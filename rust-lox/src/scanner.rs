pub struct Scan<'a> {
  token_start: &'a str,
  current: &'a str,
  line: u32,
}

pub struct Token<'a> {
  token_type: TokenType,
  text: &'a str,
  line: u32,
}

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

impl<'a> Scan<'a> {
  pub fn new(source: &str) -> Scan {
    Scan {
      token_start: source,
      current: source,
      line: 1,
    }
  }

  pub fn advance(&mut self) -> Option<char> {
    if self.at_end() {
      return None;
    }

    self.current = &self.current[1..];

    self.current[0];
  }

  pub fn scan_token(&mut self) -> Token {
    self.eat_whitespace();

    self.token_start = self.current;

    if self.at_end() {
      return self.make_token(TokenType::Eof);
    }

    if self.cu

    return self.make_token(TokenType::Eof);
  }

  pub fn print(&self) {
    if self.at_end() {
      println!("current is at end");
    }

    println!("current is {}", self.current);
  }

  fn eat_whitespace(&mut self) {
    if self.at_end() {
      return;
    }

    while self.current.chars().nth(0).unwrap() == ' ' {
      self.advance();
    }
  }

  fn at_end(&self) -> bool {
    self.current.len() == 0
  }

  fn make_token(&self, token_type: TokenType) -> Token {
    Token {
      token_type: token_type,
      text: &self.token_start[..self.current.len()],
      line: self.line,
    }
  }
}
