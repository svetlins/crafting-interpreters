use super::expression;
use super::scanner;

struct Parser<'a> {
  previous: Option<scanner::Token<'a>>,
  current: Option<scanner::Token<'a>>,
  tokens: scanner::Scan<'a>,
}

impl<'a> Parser<'a> {
  pub fn new(scan: scanner::Scan<'a>) -> Parser<'a> {
    Parser {
      previous: None,
      current: None,
      tokens: scan,
    }
  }

  pub fn parse(&mut self) -> expression::Expression {
    self.parse_expression()
  }

  fn parse_expression(&mut self) -> expression::Expression {
    // self.parse_equality()
    self.parse_primary()
  }

  fn parse_equality(&mut self) -> expression::Expression {
    let exp = self.parse_comparison();
    exp
  }

  fn parse_comparison(&mut self) -> expression::Expression {
    let exp = self.parse_term();
    exp
  }

  fn parse_term(&mut self) -> expression::Expression {
    let exp = self.parse_factor();
    exp
  }

  fn parse_factor(&mut self) -> expression::Expression {
    let exp = self.parse_unary();
    exp
  }

  fn parse_unary(&mut self) -> expression::Expression {
    let exp = self.parse_primary();
    exp
  }

  fn parse_primary(&mut self) -> expression::Expression {
    if self.match_any(&[scanner::TokenType::Number]) {
      let number_value = self.current().text.parse::<f32>();
      println!("{:?}", number_value);

      let exp = expression::Expression::Literal {
        value: self.current().text.parse().unwrap(),
      };

      return exp;
    }

    unreachable!()
  }

  fn match_any(&mut self, token_types: &[scanner::TokenType]) -> bool {
    for token_type in token_types {
      if self.check(*token_type) {
        self.advance();
        return true;
      }
    }

    false
  }

  fn peek(&mut self) -> scanner::Token {
    self.tokens.peek().unwrap()
  }

  fn check(&mut self, token_type: scanner::TokenType) -> bool {
    self.current().token_type == token_type
  }

  fn advance(&mut self) -> scanner::Token {
    let token = self.tokens.peek().unwrap();
    self.tokens.next();
    token
  }

  fn consume(&mut self, token_type: scanner::TokenType) -> bool {
    if self.check(token_type) {
      self.advance();
      return true;
    }

    false
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn test_something() {
    let scan = scanner::Scan::new("200");
    let mut parse = Parser::new(scan);

    let ast = parse.parse();

    assert_eq!(ast, expression::Expression::Literal { value: 200.0 })
  }
}
