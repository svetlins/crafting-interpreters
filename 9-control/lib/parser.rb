require 'scanner'
require 'expression'
require 'statement'

class Parser
  include TokenTypes
  include Expression
  include Statement

  class ParserError < RuntimeError; end

  def initialize(tokens, error_reporter: nil)
    @tokens = tokens
    @current = 0
    @error_reporter = error_reporter
  end

  def parse
    statements = []
    statements << parse_toplevel_statement while has_more?

    statements
  end

  def parse_toplevel_statement
    if match_any?(VAR)
      parse_variable_declaration
    else
      parse_statement
    end
  rescue ParserError => error
    synchronize
    return nil
  end

  def parse_variable_declaration
    name = consume(IDENTIFIER, "Expected variable name")

    if match_any?(EQUAL)
      initializer = parse_expression
    end

    consume(SEMICOLON, "Expected ; after variable declaration")

    VarStatement.new(name, initializer)
  end

  def parse_statement
    if match_any?(PRINT)
      parse_print_statement
    elsif match_any?(LEFT_BRACE)
      BlockStatement.new(parse_block_statement)
    elsif match_any?(IF)
      consume(LEFT_PAREN, "Expected ( before if condition")
      condition = parse_expression
      consume(RIGHT_PAREN, "Expected ) after if condition")

      then_branch = parse_statement

      if match_any?(ELSE)
        else_branch = parse_statement
      end

      IfStatement.new(condition, then_branch, else_branch)
    else
      parse_expression_statement
    end
  end

  def parse_print_statement
    expression = parse_expression
    consume(SEMICOLON, "Expected ; after expression")

    PrintStatement.new(expression)
  end

  def parse_block_statement
    statements = []

    while !check(RIGHT_BRACE) && has_more?
      statements << parse_toplevel_statement
    end

    consume(RIGHT_BRACE, "Expected } at end of block")

    statements
  end

  def parse_expression_statement
    expression = parse_expression
    consume(SEMICOLON, "Expected ; after expression")

    ExpressionStatement.new(expression)
  end

  def parse_expression
    parse_assignment
  end

  def parse_assignment
    expression = parse_or

    if match_any?(EQUAL)
      equal = previous

      if name = l_value(expression)
        value = parse_expression
        return Assign.new(name, value)
      else
        error(equal, "Expected variable name on left side of assignment")
      end
    end

    expression
  end

  def parse_or
    expression = parse_and

    while match_any?(OR)
      operator = previous
      right = parse_and
      expression = Logical.new(expression, operator, right)
    end

    expression
  end

  def parse_and
    expression = parse_equality

    while match_any?(AND)
      operator = previous
      right = parse_equality
      expression = Logical.new(expression, operator, right)
    end

    expression
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
    if match_any?(IDENTIFIER)     then return Variable.new(previous) end

    if match_any?(LEFT_PAREN)
      expression = parse_expression
      consume(RIGHT_PAREN, "Expected ')' after expression")
      return Grouping.new(expression)
    end

    raise error(peek, "Expected expression")
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

  def consume(token_type, message)
    if check(token_type)
      advance
    else
      raise error(peek, message)
    end
  end

  def error(token, message)
    @error_reporter.report_parser_error(token, message) if @error_reporter
    return ParserError.new
  end

  # Not yet utilized :shrug:
  def synchronize
    advance
    while has_more?
      return if previous.type == SEMICOLON
      return if [CLASS, FOR, FUN, IF, PRINT, RETURN, VAR, WHILE].include? peek.type

      advance
    end
  end

  def l_value(expression)
    return expression.name if expression.is_a? Variable

    return nil
  end

  def at_end?
    peek.type == EOF
  end

  def has_more?
    not at_end?
  end
end
