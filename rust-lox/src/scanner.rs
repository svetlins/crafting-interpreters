use std::str;

pub struct Scan<'a> {
  current_token: String,
  chars: DoublePeeker<std::str::Chars<'a>>,
  line: u32,
}

#[derive(Debug, PartialEq)]
pub struct Token {
  token_type: TokenType,
  text: String,
  line: u32,
}

#[derive(Debug, PartialEq)]
pub enum TokenType {
  // Single-character tokens.
  LeftParen,
  RightParen,
  LeftBrace,
  RightBrace,
  Comma,
  Dot,
  Minus,
  Plus,
  Semicolon,
  Slash,
  Star,
  // One or two character tokens.
  Bang,
  BangEqual,
  Equal,
  EqualEqual,
  Greater,
  GreaterEqual,
  Less,
  LessEqual,
  // Literals.
  Identifier,
  String,
  Number,
  // Keywords.
  And,
  Class,
  Else,
  False,
  For,
  Fun,
  If,
  Nil,
  Or,
  Print,
  Return,
  Super,
  This,
  True,
  Var,
  While,
  Error,
  Eof,
}

impl<'a> Iterator for Scan<'a> {
  type Item = Token;

  fn next(&mut self) -> Option<Self::Item> {
    if self.at_end() {
      return None;
    }

    self.scan_token()
  }
}

impl<'a> Scan<'a> {
  pub fn new(source: &str) -> Scan {
    Scan {
      current_token: String::from(""),
      chars: DoublePeeker::new(source.chars()),
      line: 1,
    }
  }

  pub fn advance(&mut self) -> char {
    if self.at_end() {
      panic!("Can't advance beyond end");
    }

    let consumed_char = self.chars.next().unwrap();

    self.current_token.push(consumed_char);

    consumed_char
  }

  fn matches(&mut self, other: char) -> bool {
    match self.peek() {
      Some(c) if c == other => {
        self.advance();
        true
      }
      _ => false,
    }
  }

  fn peek(&mut self) -> Option<char> {
    self.chars.peek()
  }

  fn peek_next(&mut self) -> Option<char> {
    self.chars.peek_next()
  }

  pub fn scan_token(&mut self) -> Option<Token> {
    if self.at_end() {
      return self.make_token(TokenType::Eof);
    }

    self.current_token = String::from("");

    self.eat_whitespace();

    let c = self.advance();

    if c.is_alphabetic() {
      return self.scan_identifier();
    }

    if c.is_ascii_digit() {
      return self.scan_number();
    }

    match c {
      '+' => self.make_token(TokenType::Plus),
      '(' => self.make_token(TokenType::LeftParen),
      ')' => self.make_token(TokenType::RightParen),
      '{' => self.make_token(TokenType::LeftBrace),
      '}' => self.make_token(TokenType::RightBrace),
      ';' => self.make_token(TokenType::Semicolon),
      '-' => self.make_token(TokenType::Minus),
      '*' => self.make_token(TokenType::Star),
      '/' => self.make_token(TokenType::Slash),
      ',' => self.make_token(TokenType::Comma),
      '!' => {
        if self.matches('=') {
          self.make_token(TokenType::BangEqual)
        } else {
          self.make_token(TokenType::Bang)
        }
      }
      '=' => {
        if self.matches('=') {
          self.make_token(TokenType::EqualEqual)
        } else {
          self.make_token(TokenType::Equal)
        }
      }
      '>' => {
        if self.matches('=') {
          self.make_token(TokenType::GreaterEqual)
        } else {
          self.make_token(TokenType::Greater)
        }
      }
      '<' => {
        if self.matches('=') {
          self.make_token(TokenType::LessEqual)
        } else {
          self.make_token(TokenType::Less)
        }
      }
      '"' => self.scan_string(),
      _ => self.make_token(TokenType::Error),
    }
  }

  fn scan_identifier(&mut self) -> Option<Token> {
    self.advance();
    self.make_token(TokenType::Error)
  }

  fn scan_number(&mut self) -> Option<Token> {
    let mut saw_decimal_point = false;

    loop {
      match self.peek() {
        Some(c) if c.is_ascii_digit() => {
          self.advance();
          ()
        }
        Some(c) if c == '.' && !saw_decimal_point => {
          saw_decimal_point = true;
          self.advance();
          ()
        }
        _ => break (),
      }
    }

    self.make_token(TokenType::Number)
  }

  fn scan_string(&mut self) -> Option<Token> {
    while self.peek() != Some('"') {
      self.advance();
    }

    self.advance();

    self.make_token(TokenType::String)
  }

  fn eat_whitespace(&mut self) {
    if self.at_end() {
      return;
    }

    while self.peek() == Some(' ') {
      self.advance();
    }
  }

  fn at_end(&mut self) -> bool {
    self.peek() == None
  }

  fn make_token(&self, token_type: TokenType) -> Option<Token> {
    Some(Token {
      token_type: token_type,
      text: self.current_token.clone(),
      line: self.line,
    })
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn test_construct() {
    Scan::new("print 200;");
  }

  #[test]
  fn test_single_char_op() {
    let mut scan = Scan::new("+");
    assert_eq!(scan.scan_token().unwrap().token_type, TokenType::Plus);
  }

  #[test]
  fn test_multiple_single_char_op() {
    let mut scan = Scan::new("+-*");
    assert_eq!(scan.scan_token().unwrap().token_type, TokenType::Plus);
    assert_eq!(scan.scan_token().unwrap().token_type, TokenType::Minus);
    assert_eq!(scan.scan_token().unwrap().token_type, TokenType::Star);
  }

  #[test]
  fn test_whitespace() {
    let mut scan = Scan::new("       +         ");
    assert_eq!(scan.scan_token().unwrap().token_type, TokenType::Plus);
  }

  #[test]
  fn test_double_char_op() {
    let mut scan = Scan::new("!=");
    assert_eq!(scan.scan_token().unwrap().token_type, TokenType::BangEqual);
  }

  #[test]
  fn test_double_char_confusion_op() {
    let mut scan = Scan::new("!");
    assert_eq!(scan.scan_token().unwrap().token_type, TokenType::Bang);
  }

  #[test]
  fn test_greater() {
    let mut scan = Scan::new(">");
    assert_eq!(scan.scan_token().unwrap().token_type, TokenType::Greater);
  }

  #[test]
  fn test_greater_equal() {
    let mut scan = Scan::new(">=");
    assert_eq!(
      scan.scan_token().unwrap().token_type,
      TokenType::GreaterEqual
    );
  }

  #[test]
  fn test_string() {
    let mut scan = Scan::new("\"some string\"");
    assert_eq!(scan.scan_token().unwrap().token_type, TokenType::String);
  }

  #[test]
  fn test_string_and_after() {
    let mut scan = Scan::new("\"some string\"+");
    scan.scan_token();
    assert_eq!(scan.scan_token().unwrap().token_type, TokenType::Plus);
  }

  #[test]
  fn test_iterable() {
    let scan = Scan::new("\"some string\"+");
    let tokens: Vec<Token> = scan.collect();

    assert_eq!(
      tokens,
      Vec::from([
        Token {
          token_type: TokenType::String,
          text: String::from("\"some string\""),
          line: 1
        },
        Token {
          token_type: TokenType::Plus,
          text: String::from("+"),
          line: 1
        }
      ])
    );
  }

  #[test]
  fn test_integer() {
    let mut scan = Scan::new("42");
    let token = scan.scan_token().unwrap();
    assert_eq!(token.token_type, TokenType::Number);
    assert_eq!(token.text, String::from("42"));
  }

  #[test]
  fn test_decimal() {
    let mut scan = Scan::new("42.69");
    let token = scan.scan_token().unwrap();
    assert_eq!(token.token_type, TokenType::Number);
    assert_eq!(token.text, String::from("42.69"));
  }

  #[test]
  fn test_malformed_decimal() {
    let mut scan = Scan::new("42.69.666");
    let token = scan.scan_token().unwrap();
    assert_eq!(token.token_type, TokenType::Number);
    assert_eq!(token.text, String::from("42.69"));
  }

  #[test]
  fn test_empty() {
    let mut scan = Scan::new("");
    assert_eq!(scan.scan_token().unwrap().token_type, TokenType::Eof);
  }
}

// ---------------------------------

struct DoublePeeker<I: Iterator> {
  first_peeked: Option<Option<I::Item>>,
  second_peeked: Option<Option<I::Item>>,
  iter: I,
}

impl<I: Iterator> DoublePeeker<I>
where
  I::Item: std::fmt::Debug + Copy,
{
  fn new(iter: I) -> Self {
    DoublePeeker {
      iter,
      first_peeked: None,
      second_peeked: None,
    }
  }

  fn peek(&mut self) -> Option<I::Item> {
    self.first_peeked.get_or_insert_with(|| self.iter.next());
    self.first_peeked.unwrap()
  }

  fn peek_next(&mut self) -> Option<I::Item> {
    self.first_peeked.get_or_insert_with(|| self.iter.next());
    self.second_peeked.get_or_insert_with(|| self.iter.next());

    self.second_peeked.unwrap()
  }
}

impl<I: Iterator> Iterator for DoublePeeker<I> {
  type Item = I::Item;

  fn next(&mut self) -> Option<Self::Item> {
    let next_value = match self.first_peeked.take() {
      Some(value) => value,
      None => self.iter.next(),
    };

    self.first_peeked = self.second_peeked.take();

    next_value
  }
}

#[cfg(test)]
mod tests_double_peekable {
  use super::*;

  #[test]
  fn test_next() {
    let vec = Vec::from([1, 2, 3, 4, 5]);
    let mut double_peeker = DoublePeeker::new(vec.iter());

    assert_eq!(Some(&1), double_peeker.next());
    assert_eq!(Some(&2), double_peeker.next());
    assert_eq!(Some(&3), double_peeker.next());
    assert_eq!(Some(&4), double_peeker.next());
    assert_eq!(Some(&5), double_peeker.next());
    assert_eq!(None, double_peeker.next());
  }

  #[test]
  fn test_peek() {
    let vec = Vec::from([1, 2, 3, 4, 5]);
    let mut double_peeker = DoublePeeker::new(vec.iter());

    assert_eq!(Some(&1), double_peeker.next());
    assert_eq!(Some(&2), double_peeker.next());
    assert_eq!(Some(&3), double_peeker.next());
    assert_eq!(Some(&4), double_peeker.peek());
    assert_eq!(Some(&4), double_peeker.next());
    assert_eq!(Some(&5), double_peeker.next());
    assert_eq!(None, double_peeker.next());
    println!("{:?}", vec);
  }

  #[test]
  fn test_peek_next() {
    let vec = Vec::from([1, 2, 3, 4, 5]);

    let mut double_peeker = DoublePeeker::new(vec.iter());

    assert_eq!(Some(&1), double_peeker.next());
    assert_eq!(Some(&2), double_peeker.next());
    assert_eq!(Some(&3), double_peeker.next());
    assert_eq!(Some(&4), double_peeker.peek());
    assert_eq!(Some(&5), double_peeker.peek_next());
    assert_eq!(Some(&4), double_peeker.next());
    assert_eq!(Some(&5), double_peeker.next());
    assert_eq!(None, double_peeker.next());
    println!("{:?}", vec);
  }

  #[test]
  fn test_peek_strings() {
    let vec = Vec::from(["a", "b", "c", "d", "e"]);

    let mut double_peeker = DoublePeeker::new(vec.iter());

    assert_eq!(Some(&"a"), double_peeker.next());
    assert_eq!(Some(&"b"), double_peeker.next());
    assert_eq!(Some(&"c"), double_peeker.next());
    assert_eq!(Some(&"d"), double_peeker.peek());
    assert_eq!(Some(&"e"), double_peeker.peek_next());
    assert_eq!(Some(&"d"), double_peeker.next());
    assert_eq!(None, double_peeker.peek_next());
    assert_eq!(Some(&"e"), double_peeker.next());
    assert_eq!(None, double_peeker.next());
    println!("{:?}", vec);
  }
}
