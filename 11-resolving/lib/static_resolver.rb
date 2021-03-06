class StaticResolver
  module FunctionTypes
    NONE = "NONE"
    FUNCTION = "FUNCTION"
  end

  def initialize(interpreter, error_reporter: nil)
    @interpreter = interpreter
    @scopes = []
    @current_function = FunctionTypes::NONE
    @error_reporter = error_reporter
  end

  def resolve(resolvable)
    if resolvable.is_a? Array
      resolvable.each { |resolvable_element| resolve(resolvable_element) }
    elsif resolvable.statement?
      resolvable.accept(self)
    elsif resolvable.expression?
      resolvable.accept(self)
    else
      raise
    end
  end

  def begin_scope
    @scopes << {}
  end

  def end_scope
    @scopes.pop
  end

  def declare(name)
    return if @scopes.empty?
    error(name, "Variable `#{name.lexeme}` already declared") if @scopes.last.has_key?(name.lexeme)
    @scopes.last[name.lexeme] = false
  end

  def define(name)
    return if @scopes.empty?
    @scopes.last[name.lexeme] = true
  end

  def resolve_local(expression, name)
    @scopes.reverse.each_with_index do |scope, index|
      if scope.has_key? name.lexeme
        @interpreter.resolve(expression, index)
        break
      end
    end
  end

  def resolve_function(function, type)
    enclosing_function = @current_function
    @current_function = type
    begin_scope

    function.parameters.each do |parameter|
      declare(parameter)
      define(parameter)
    end

    resolve(function.body)

    end_scope

    @current_function = enclosing_function
  end

  def error(token, message)
    if @error_reporter
      @error_reporter.report_static_analysis_error(token, message)
    end
  end

  def visit_block_statement(block_statement)
    begin_scope
    resolve(block_statement.statements)
    end_scope

    return nil
  end

  def visit_var_statement(var_statement)
    declare(var_statement.name)

    if var_statement.initializer
      resolve(var_statement.initializer)
    end

    define(var_statement.name)

    return nil
  end

  def visit_variable(variable_expression)
    if !@scopes.empty? && @scopes.last[variable_expression.name.lexeme] == false
      error(variable_expression.name, "Can't read local variable in its own initializer")
    end

    resolve_local(variable_expression, variable_expression.name)

    return nil
  end

  def visit_assign(assign_expression)
    resolve(assign_expression.value)
    resolve_local(assign_expression, assign_expression.name)

    return nil
  end

  def visit_function_statement(function_statement)
    declare(function_statement.name)
    define(function_statement.name)
    resolve_function(function_statement, FunctionTypes::FUNCTION)

    return nil
  end

  # rest

  def visit_expression_statement(expression_statement)
    resolve(expression_statement.expression)

    return nil
  end

  def visit_if_statement(if_statement)
    resolve(if_statement.condition)
    resolve(if_statement.then_branch)
    resolve(if_statement.else_branch) if if_statement.else_branch

    return nil
  end

  def visit_print_statement(print_statement)
    resolve(print_statement.expression)

    return nil
  end

  def visit_return_statement(return_statement)
    if @current_function == FunctionTypes::NONE
      error(return_statement.keyword, "Can't return outside of function")
    end

    resolve(return_statement.value)

    return nil
  end

  def visit_while_statement(while_statement)
    resolve(while_statement.condition)
    resolve(while_statement.body)

    return nil
  end

  def visit_binary(binary_expression)
    resolve(binary_expression.left)
    resolve(binary_expression.right)

    return nil
  end

  def visit_call(call_expression)
    resolve(call_expression.callee)
    call_expression.arguments.each do |argument|
      resolve(argument)
    end

    return nil
  end

  def visit_grouping(grouping_expression)
    resolve(grouping_expression.expression)

    return nil
  end

  def visit_literal(literal_expression)
  end

  def visit_logical(logical_expression)
    resolve(logical_expression.left)
    resolve(logical_expression.right)

    return nil
  end

  def visit_unary(unary_expression)
    resolve(unary_expression.right)

    return nil
  end
end
