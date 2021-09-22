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
    elsif match_any?(FUN)
      parse_function_declaration(:function)
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

  def parse_function_declaration(kind)
    name = consume(IDENTIFIER, "Expected #{kind} name")
    consume(LEFT_PAREN, "Expected ( after #{kind} name")

    parameters = []

    if !check(RIGHT_PAREN)
      loop do
        if parameters.size > 255
          error(peek, "Expected function to have fewer than 255 parameters")
        end

        parameters << consume(IDENTIFIER, "Expected parameter name")
        break unless match_any?(COMMA)
      end
    end

    consume(RIGHT_PAREN, "Expected ) after #{kind} parameter list")
    consume(LEFT_BRACE, "Expected { before #{kind} body")

    body = parse_block_statement

    FunctionStatement.new(name, parameters, body)
  end

  def parse_statement
    if match_any?(PRINT) then parse_print_statement
    elsif match_any?(LEFT_BRACE) then BlockStatement.new(parse_block_statement)
    elsif match_any?(IF) then parse_if
    elsif match_any?(WHILE) then parse_while
    elsif match_any?(FOR) then parse_for
    elsif match_any?(RETURN) then parse_return
    else parse_expression_statement
    end
  end

  def parse_if
    consume(LEFT_PAREN, "Expected ( before if condition")
    condition = parse_expression
    consume(RIGHT_PAREN, "Expected ) after if condition")

    then_branch = parse_statement

    if match_any?(ELSE)
      else_branch = parse_statement
    end

    IfStatement.new(condition, then_branch, else_branch)
  end

  def parse_while
    consume(LEFT_PAREN, "Expected ( before while condition")
    condition = parse_expression
    consume(RIGHT_PAREN, "Expected ) after while condition")

    body = parse_statement

    WhileStatement.new(condition, body)
  end

  def parse_for
    consume(LEFT_PAREN, "Expected ( after for")

    if match_any?(SEMICOLON)
      initializer = nil
    elsif match_any?(VAR)
      initializer = parse_variable_declaration
    else
      initializer = parse_expression_statement
    end

    if !check(SEMICOLON)
      condition = parse_expression
    end

    consume(SEMICOLON, "Expected ; after for condition")

    if !check(RIGHT_PAREN)
      increment = parse_expression
    end

    consume(RIGHT_PAREN, "Expected ) after for clauses")

    body = parse_statement

    if increment != nil
      body = BlockStatement.new([body, increment])
    end

    body = WhileStatement.new(condition || Literal.new(true), body)

    if initializer
      body = BlockStatement.new([initializer, body])
    end

    body
  end

  def parse_return
    keyword = previous

    value =
      if !check(SEMICOLON)
        parse_expression
      end

    consume(SEMICOLON, "Expected semicolon after return")

    ReturnStatement.new(keyword, value)
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

    parse_call
  end

  def parse_call
    expression = parse_primary

    loop do
      if match_any?(LEFT_PAREN)
        paren = previous
        expression = parse_finish_call(expression)
      else
        break
      end
    end

    expression
  end

  def parse_finish_call(callee)
    arguments = []

    if !check(RIGHT_PAREN)
      loop do
        if arguments.count > 255
          error(peek, "Can't have more than 255 arguments")
        end

        arguments << parse_expression

        break unless match_any?(COMMA)
      end
    end

    close_paren = consume(RIGHT_PAREN, "Expected ) after argument list")

    Call.new(callee, close_paren, arguments)
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
