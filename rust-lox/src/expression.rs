use super::scanner;

#[derive(Debug, PartialEq)]
pub enum Expression<'a> {
  Binary {
    left: Box<Expression<'a>>,
    operator: scanner::Token<'a>,
    right: Box<Expression<'a>>,
  },
  Grouping {
    expression: Box<Expression<'a>>,
  },
  Literal {
    value: f32,
  },
  Unary {
    operator: scanner::Token<'a>,
    right: Box<Expression<'a>>,
  },
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn test_something() {
    let left = Box::new(Expression::Literal { value: 666.0 });
    let right = Box::new(Expression::Literal { value: 42.0 });
    Expression::Binary {
      left: left,
      operator: scanner::Token {
        token_type: scanner::TokenType::Plus,
        text: "+",
        line: 1,
      },
      right: right,
    };
  }
}
