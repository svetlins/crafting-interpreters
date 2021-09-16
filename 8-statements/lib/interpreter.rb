require 'scanner'

class Interpreter
  include TokenTypes

  class LoxRuntimeError < RuntimeError
    attr_reader :token

    def initialize(token, message)
      @token = token
      super(message)
    end
  end

  def initialize(error_reporter: nil)
    @error_reporter = error_reporter
  end

  def interpret(expression)
    expression.accept(self)
  rescue LoxRuntimeError => error
    @error_reporter.report_runtime_error(error.token, error.message) if @error_reporter
  end

  def visit_binary(binary)
    left = interpret(binary.left)
    right = interpret(binary.right)

    case binary.operator.type
    when MINUS
      check_number(binary.operator, left, right)
      left - right
    when SLASH
      check_number(binary.operator, left, right)
      left / right
    when STAR
      check_number(binary.operator, left, right)
      left * right
    when PLUS
      if (left.is_a?(Numeric) && right.is_a?(Numeric)) || (left.is_a?(String) && right.is_a?(String))
        left + right
      else
        raise LoxRuntimeError.new(binary.operator, "Operands must be two numbers or two strings")
      end
    when GREATER
      check_number(binary.operator, left, right)
      left > right
    when GREATER_EQUAL
      check_number(binary.operator, left, right)
      left >= right
    when LESS
      check_number(binary.operator, left, right)
      left < right
    when LESS_EQUAL
      check_number(binary.operator, left, right)
      left <= right
    when BANG_EQUAL
      !lox_equal?(left, right)
    when EQUAL_EQUAL
      lox_equal?(left, right)
    else
      raise
    end
  end

  def visit_grouping(grouping)
    interpret(grouping.expression)
  end

  def visit_literal(literal)
    literal.value
  end

  def visit_unary(unary)
    right = interpret(unary.right)

    case unary.operator.type
    when BANG
      !truthy?(right)
    when MINUS
      -right
    end
  end

  def parenthesize(name, *items)
    "(" + name + items.map { |item| " #{item.accept(self)}" }.join + ")"
  end

  def truthy?(value)
    !(value.nil? || value == false)
  end

  def lox_equal(left, right)
    left == right
  end

  def check_number(operator, *operands)
    operands.each do |operand|
      unless operand.is_a? Float
        raise LoxRuntimeError.new(operator, "Must be a number")
      end
    end
  end
end
