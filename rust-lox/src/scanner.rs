use std::str;

pub struct Scan<'a> {
  current_token: String,
  chars: str::Chars<'a>,
  next_char: Option<char>,
  current_char: Option<char>,
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
    let mut chars = source.chars();

    let current_char = chars.next();
    let next_char = chars.next();

    Scan {
      current_token: String::from(""),
      chars: chars,
      next_char: next_char,
      current_char: current_char,
      line: 1,
    }
  }

  pub fn advance(&mut self) -> char {
    if self.at_end() {
      panic!("Can't advance beyond end");
    }

    let consumed_char = self.current_char.unwrap();

    self.current_char = self.next_char;
    self.next_char = self.chars.next();

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

  fn peek(&self) -> Option<char> {
    self.current_char
  }

  fn peek_next(&self) -> Option<char> {
    self.next_char
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

  fn at_end(&self) -> bool {
    self.current_char == None
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

struct DoublePeekable<I: Iterator> {
  iter: I,
  first_peeked: Option<Option<I::Item>>,
  second_peeked: Option<Option<I::Item>>,
}

impl<I: Iterator> DoublePeekable<I> {
  pub fn new(iter: I) -> DoublePeekable<I> {
    DoublePeekable {
      iter,
      first_peeked: None,
      second_peeked: None,
    }
  }
}

impl<I: Iterator> Iterator for DoublePeekable<I> {
  type Item = I::Item;

  fn next(&mut self) -> Option<I::Item> {
    match self.first_peeked.take() {
      Some(v) => {
        self.first_peeked = self.second_peeked.take();
        self.second_peeked = None;
        v
      }
      None => self.iter.next(),
    }
  }
}

impl<I: Iterator> DoublePeekable<I> {
  pub fn peek(&mut self) -> Option<&I::Item> {
    let iter = &mut self.iter;
    self
      .first_peeked
      .get_or_insert_with(|| iter.next())
      .as_ref()
  }

  pub fn peek_next(&mut self) -> Option<&I::Item> {
    let iter = &mut self.iter;

    self.first_peeked.get_or_insert_with(|| iter.next());

    self
      .second_peeked
      .get_or_insert_with(|| iter.next())
      .as_ref()
  }
}

#[cfg(test)]
mod tests2 {
  use super::*;

  #[test]
  fn test_double_peekable() {
    let vec: Vec<u32> = Vec::from([1, 2, 3, 4, 5]);
    let mut double_peekable = DoublePeekable::new(vec.iter());

    println!("HIIiiiiiiiiii {:?}", double_peekable.next());
    println!("HIIiiiiiiiiii {:?}", double_peekable.peek());
    println!("HIIiiiiiiiiii {:?}", double_peekable.peek_next());
    println!("HIIiiiiiiiiii {:?}", double_peekable.next());
  }
}
