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

    Some(self.scan_token())
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

    let current_char = self.current_char.unwrap();

    self.current_char = self.next_char;
    self.next_char = self.chars.next();

    self.current_token.push(current_char);

    current_char
  }

  fn matches(&mut self, c: char) -> bool {
    if self.peek(c) {
      self.advance();
      true
    } else {
      false
    }
  }

  fn peek(&self, c: char) -> bool {
    if let Some(current_char) = self.current_char {
      current_char == c
    } else {
      false
    }
  }

  fn peek_next(&self, c: char) -> bool {
    if let Some(next_char) = self.next_char {
      next_char == c
    } else {
      false
    }
  }

  pub fn scan_token(&mut self) -> Token {
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

  fn scan_identifier(&mut self) -> Token {
    self.advance();
    self.make_token(TokenType::Error)
  }

  fn scan_number(&mut self) -> Token {
    panic!("ko 6i praim");
  }

  fn scan_string(&mut self) -> Token {
    while !self.peek('"') {
      self.advance();
    }

    self.advance();

    self.make_token(TokenType::String)
  }

  fn eat_whitespace(&mut self) {
    if self.at_end() {
      return;
    }

    while self.peek(' ') {
      self.advance();
    }
  }

  fn at_end(&self) -> bool {
    self.current_char == None
  }

  fn make_token(&self, token_type: TokenType) -> Token {
    Token {
      token_type: token_type,
      text: self.current_token.clone(),
      line: self.line,
    }
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
    assert_eq!(scan.scan_token().token_type, TokenType::Plus);
  }

  #[test]
  fn test_multiple_single_char_op() {
    let mut scan = Scan::new("+-*");
    assert_eq!(scan.scan_token().token_type, TokenType::Plus);
    assert_eq!(scan.scan_token().token_type, TokenType::Minus);
    assert_eq!(scan.scan_token().token_type, TokenType::Star);
  }

  #[test]
  fn test_whitespace() {
    let mut scan = Scan::new("       +         ");
    assert_eq!(scan.scan_token().token_type, TokenType::Plus);
  }

  #[test]
  fn test_double_char_op() {
    let mut scan = Scan::new("!=");
    assert_eq!(scan.scan_token().token_type, TokenType::BangEqual);
  }

  #[test]
  fn test_double_char_confusion_op() {
    let mut scan = Scan::new("!");
    assert_eq!(scan.scan_token().token_type, TokenType::Bang);
  }

  #[test]
  fn test_greater() {
    let mut scan = Scan::new(">");
    assert_eq!(scan.scan_token().token_type, TokenType::Greater);
  }

  #[test]
  fn test_greater_equal() {
    let mut scan = Scan::new(">=");
    assert_eq!(scan.scan_token().token_type, TokenType::GreaterEqual);
  }

  #[test]
  fn test_string() {
    let mut scan = Scan::new("\"some string\"");
    assert_eq!(scan.scan_token().token_type, TokenType::String);
  }

  #[test]
  fn test_string_and_after() {
    let mut scan = Scan::new("\"some string\"+");
    scan.scan_token();
    assert_eq!(scan.scan_token().token_type, TokenType::Plus);
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
    assert_eq!(scan.scan_token().token_type, TokenType::Number);
  }
}
