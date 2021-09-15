require 'scanner'
class Parser
  include TokenTypes
  include Expression

  def initialize(tokens)
    @tokens = tokens
    @current = 0
  end

  def parse_expression
    parse_equality
  end

  def parse_equality
    expression = parse_comparison

    while match_any?(BANG_EQUAL, EQUAL_EQUAL)
      operator = previous
      right_expression = parse_comparison

      expression = Binary.new(
        expression,
        operator,
        right_expression
      )
    end

    expression
  end

  def parse_comparison
    expression = parse_term

    while match_any?(GREATER, GREATER_EQUAL, LESS, LESS_EQUAL)
      operator = previous
      right_expression = parse_term

      expression = Binary.new(
        expression,
        operator,
        right_expression
      )
    end

    expression
  end

  def parse_term
    expression = parse_factor

    while match_any?(PLUS, MINUS)
      operator = previous
      right_expression = parse_factor

      expression = Binary.new(
        expression,
        operator,
        right_expression
      )
    end

    expression
  end

  def parse_factor
    expression = parse_unary

    while match_any?(STAR, SLASH)
      operator = previous
      right_expression = parse_unary

      expression = Binary.new(
        expression,
        operator,
        right_expression
      )
    end

    expression
  end

  def parse_unary
    if match_any?(BANG, MINUS)
      operator = previous
      right = parse_unary

      return Unary.new(operator, right)
    end

    parse_primary
  end

  def parse_primary
    if match_any?(NUMBER, STRING) then return Literal.new(previous.literal) end
    if match_any?(FALSE)          then return Literal.new(false) end
    if match_any?(TRUE)           then return Literal.new(true) end
    if match_any?(NIL)            then return Literal.new(nil) end

    if match_any?(LEFT_PAREN)
      expression = parse_expression
      consume(RIGHT_PAREN, "Expected ')' after expression")
      Grouping.new(expression)
    end
  end

  def match_any?(*token_types)
    token_types.each do |token_type|
      if check(token_type)
        advance
        return true
      end
    end

    return false
  end

  def check(token_type)
    return false if at_end?
    peek.type == token_type
  end

  def peek
    @tokens[@current]
  end

  def previous
    @tokens[@current - 1]
  end

  def advance
    @current += 1 if has_more?
    previous
  end

  def at_end?
    peek.type == EOF
  end

  def has_more?
    not at_end?
  end
end
