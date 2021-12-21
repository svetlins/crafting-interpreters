require 'environment'
require 'lox_function'
require 'lox_instance'
require 'lox_class'
require 'scanner'

require 'time'


class Interpreter
  include TokenTypes

  class LoxRuntimeError < RuntimeError
    attr_reader :token

    def initialize(token, message)
      @token = token
      super(message)
    end
  end

  attr_reader :globals

  def initialize(error_reporter: nil)
    @globals = Environment.new
    @environment = @globals
    define_globals
    @error_reporter = error_reporter
  end

  def define_globals
    @globals.define(
      "clock",
      Struct.new(:_dummy) do
        def arity = 0;
        def lox_call(*) = Time.now.to_i;
        def to_s = "<native fn>"
      end.new
    )

    @globals.define(
      "assert",
      Struct.new(:_dummy) do
        def arity = 2;

        def lox_call(_interpreter, arguments)
          assertion = arguments.first
          message = arguments.last

          print message

          unless assertion
            puts "\t\tFAIL"
            exit(1)
          end

          puts "\t\tOK"
        end

        def to_s = "<native fn>"
      end.new
    )
  end

  def interpret(statements, static_resolutions)
    @static_resolutions = static_resolutions

    statements.each do |statement|
      execute(statement)
    end
  rescue LoxRuntimeError => error
    @error_reporter.report_runtime_error(error.token, error.message) if @error_reporter
  end

  def execute(statement)
    statement.accept(self)
  end

  def evaluate(expression)
    expression.accept(self)
  end

  def visit_print_statement(print_statement)
    puts evaluate(print_statement.expression)
    return nil
  end

  def visit_block_statement(block_statement)
    execute_block(block_statement.statements, Environment.new(@environment))
    return nil
  end

  def visit_expression_statement(expression_statement)
    evaluate(expression_statement.expression)
  end

  def visit_var_statement(var_statement)
    @environment.define(
      var_statement.name.lexeme,
      var_statement.initializer ? evaluate(var_statement.initializer) : nil
    )

    return nil
  end

  def visit_function_statement(function_statement)
    lox_function = LoxFunction.new(function_statement, @environment, false)
    @environment.define(
      function_statement.name.lexeme,
      lox_function
    )

    return nil
  end

  def visit_class_statement(class_statement)
    if class_statement.superclass
      superclass = evaluate(class_statement.superclass)

      unless superclass.is_a? LoxClass
        raise LoxRuntimeError.new(class_statement.superclass, "Superclass is not a class")
      end
    end

    @environment.define(class_statement.name.lexeme, nil)

    if superclass
      method_environment = Environment.new(@environment)
      method_environment.define('super', superclass)
    else
      method_environment = @environment
    end

    methods = class_statement.methods.map do |method|
      [method.name.lexeme, LoxFunction.new(method, method_environment, method.name.lexeme == 'init')]
    end.to_h

    klass = LoxClass.new(class_statement.name.lexeme, superclass, methods)
    @environment.assign(class_statement.name, klass)

    return nil
  end

  def visit_if_statement(if_statement)
    evaluated_condition = evaluate(if_statement.condition)

    if truthy?(evaluated_condition)
      execute(if_statement.then_branch)
    elsif if_statement.else_branch
      execute(if_statement.else_branch)
    end

    return nil
  end

  def visit_while_statement(while_statement)
    while truthy?(evaluate(while_statement.condition))
      execute(while_statement.body)
    end

    return nil
  end

  def visit_return_statement(return_statement)
    if return_statement.value
      value = evaluate(return_statement.value)
    end

    throw :lox_return, value
  end

  def visit_assign(assign)
    value = evaluate(assign.value)

    depth = @static_resolutions[assign.object_id]

    if depth
      @environment.assign_at(depth, assign.name, value)
    else
      @globals.assign(assign.name, value)
    end

    value
  end

  def visit_binary(binary)
    left = evaluate(binary.left)
    right = evaluate(binary.right)

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
    evaluate(grouping.expression)
  end

  def visit_literal(literal)
    literal.value
  end

  def visit_logical(logical)
    left = evaluate(logical.left)

    if logical.operator.type == OR
      if truthy?(left) then return left end
    else
      if !truthy?(left) then return left end
    end

    evaluate(logical.right)
  end

  def visit_unary(unary)
    right = evaluate(unary.right)

    case unary.operator.type
    when BANG
      !truthy?(right)
    when MINUS
      -right
    end
  end

  def visit_variable(variable)
    lookup_variable(variable.name, variable)
  end

  def visit_this_expression(this_expression)
    lookup_variable(this_expression.keyword, this_expression)
  end

  def lookup_variable(name, expression)
    depth = @static_resolutions[expression.object_id]

    if depth
      @environment.get_at(depth, name)
    else
      @globals.get(name)
    end
  end

  def visit_call(call_expression)
    callee = evaluate(call_expression.callee)

    evaluated_arguments = call_expression.arguments.map do |argument|
      evaluate(argument)
    end

    unless callee.respond_to? :lox_call
      raise LoxRuntimeError.new(call_expression.paren, "Expected function or class for callee")
    end

    # assume callee has #arity if it has #lox_call
    if evaluated_arguments.count != callee.arity
      raise LoxRuntimeError.new(
        call_expression.paren,
        "Expected #{callee.arity} arguments but got #{evaluated_arguments.count}"
      )
    end

    callee.lox_call(self, evaluated_arguments)
  end

  def visit_get_expression(get_expression)
    object = evaluate(get_expression.object)

    if object.is_a? LoxInstance
      object.get(get_expression.name)
    else
      raise LoxRuntimeError.new(get_expression.name, "Can't access property of non-object vlaue")
    end
  end

  def visit_set_expression(set_expression)
    object = evaluate(set_expression.object)

    if object.is_a? LoxInstance
      object.set(set_expression.name, evaluate(set_expression.value))
    else
      raise LoxRuntimeError.new(set_expression.name, "Can't access property of non-object vlaue")
    end
  end

  def visit_super_expression(super_expression)
    depth = @static_resolutions[super_expression.object_id]
    superclass = @environment.get_at(depth, super_expression.keyword)

    method = superclass.find_method(super_expression.method_name.lexeme)

    unless method
      raise LoxRuntimeError.new(super_expression.method_name, "Undefined property #{super_expression.method_name.lexeme}")
    end

    require 'ostruct'
    instance = @environment.get_at(depth - 1, OpenStruct.new(lexeme: 'this')) #

    method.bind(instance)
  end

  def execute_block(statements, environment)
    saved_environment = @environment
    @environment = environment

    statements.each do |statement|
      execute(statement)
    end
  ensure
    @environment = saved_environment
  end

  def truthy?(value)
    !(value.nil? || value == false)
  end

  def lox_equal?(left, right)
    left == right
  end

  def check_number(operator, *operands)
    operands.each do |operand|
      unless operand.is_a? Numeric
        raise LoxRuntimeError.new(operator, "Must be a number")
      end
    end
  end
end
