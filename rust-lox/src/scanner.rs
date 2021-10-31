use super::util;
use std::str;

pub struct Scan<'a> {
  current_token: String,
  chars: util::DoublePeeker<std::str::Chars<'a>>,
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
    match self.scan_token() {
      Some(token) if token.token_type == TokenType::Eof => None,
      Some(token) => Some(token),
      None => None,
    }
  }
}

impl<'a> Scan<'a> {
  pub fn new(source: &str) -> Scan {
    Scan {
      current_token: String::from(""),
      chars: util::DoublePeeker::new(source.chars()),
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
    self.eat_whitespace();

    self.current_token = String::from("");

    if self.at_end() {
      return self.make_token(TokenType::Eof);
    }

    let c = self.advance();

    if c.is_alphabetic() || c == '_' {
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
      '.' => self.make_token(TokenType::Dot),
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
    while !self.at_end()
      && self
        .peek()
        .map(|c| c.is_alphabetic() || c == '_' || c.is_ascii_digit())
        == Some(true)
    {
      self.advance();
    }

    self.make_token(self.current_identifier_type())
  }

  fn current_identifier_type(&self) -> TokenType {
    // Book implementation is with hard-coded trie but I'm lazy
    match self.current_token.as_str() {
      "and" => TokenType::And,
      "class" => TokenType::Class,
      "else" => TokenType::Else,
      "if" => TokenType::If,
      "nil" => TokenType::Nil,
      "or" => TokenType::Or,
      "print" => TokenType::Print,
      "return" => TokenType::Return,
      "super" => TokenType::Super,
      "var" => TokenType::Var,
      "while" => TokenType::While,
      "fn" => TokenType::Fun,
      "false" => TokenType::False,
      "for" => TokenType::For,
      "this" => TokenType::This,
      "true" => TokenType::True,
      _ => TokenType::Identifier,
    }
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
    loop {
      match self.peek() {
        Some(c) if c == '\n' => {
          self.line += 1;
          self.advance();
        }
        Some(c) if c == '/' => {
          if self.peek_next() == Some('/') {
            while !self.at_end() && self.peek() != Some('\n') {
              self.advance();
            }
          }
        }
        Some(c) if c.is_whitespace() => {
          self.advance();
        }
        _ => {
          break;
        }
      }
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

  #[test]
  fn test_keywords() {
    let scan = Scan::new("print 1");
    let tokens: Vec<Token> = scan.collect();

    assert_eq!(
      tokens,
      Vec::from([
        Token {
          token_type: TokenType::Print,
          text: String::from("print"),
          line: 1
        },
        Token {
          token_type: TokenType::Number,
          text: String::from("1"),
          line: 1
        }
      ])
    )
  }

  #[test]
  fn test_identifier() {
    let scan = Scan::new("count + 1");
    let tokens: Vec<Token> = scan.collect();

    assert_eq!(
      tokens,
      Vec::from([
        Token {
          token_type: TokenType::Identifier,
          text: String::from("count"),
          line: 1
        },
        Token {
          token_type: TokenType::Plus,
          text: String::from("+"),
          line: 1
        },
        Token {
          token_type: TokenType::Number,
          text: String::from("1"),
          line: 1
        }
      ])
    )
  }

  #[test]
  fn test_newlines() {
    let source = r#"
      fn a_fun(p) {
        var l = p + 1;
        return v + 1;
      }
      "#;

    let scan = Scan::new(source);
    let tokens: Vec<Token> = scan.collect();

    assert_eq!(
      tokens,
      Vec::from([
        Token {
          token_type: TokenType::Fun,
          text: String::from("fn"),
          line: 2
        },
        Token {
          token_type: TokenType::Identifier,
          text: String::from("a_fun"),
          line: 2
        },
        Token {
          token_type: TokenType::LeftParen,
          text: String::from("("),
          line: 2
        },
        Token {
          token_type: TokenType::Identifier,
          text: String::from("p"),
          line: 2
        },
        Token {
          token_type: TokenType::RightParen,
          text: String::from(")"),
          line: 2
        },
        Token {
          token_type: TokenType::LeftBrace,
          text: String::from("{"),
          line: 2
        },
        Token {
          token_type: TokenType::Var,
          text: String::from("var"),
          line: 3
        },
        Token {
          token_type: TokenType::Identifier,
          text: String::from("l"),
          line: 3
        },
        Token {
          token_type: TokenType::Equal,
          text: String::from("="),
          line: 3
        },
        Token {
          token_type: TokenType::Identifier,
          text: String::from("p"),
          line: 3
        },
        Token {
          token_type: TokenType::Plus,
          text: String::from("+"),
          line: 3
        },
        Token {
          token_type: TokenType::Number,
          text: String::from("1"),
          line: 3
        },
        Token {
          token_type: TokenType::Semicolon,
          text: String::from(";"),
          line: 3
        },
        Token {
          token_type: TokenType::Return,
          text: String::from("return"),
          line: 4
        },
        Token {
          token_type: TokenType::Identifier,
          text: String::from("v"),
          line: 4
        },
        Token {
          token_type: TokenType::Plus,
          text: String::from("+"),
          line: 4
        },
        Token {
          token_type: TokenType::Number,
          text: String::from("1"),
          line: 4
        },
        Token {
          token_type: TokenType::Semicolon,
          text: String::from(";"),
          line: 4
        },
        Token {
          token_type: TokenType::RightBrace,
          text: String::from("}"),
          line: 5
        },
      ])
    )
  }
}
