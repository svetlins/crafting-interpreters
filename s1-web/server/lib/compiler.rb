require 'chunk'

module FunctionType
  SCRIPT = "SCRIPT"
  FUNCTION = "FUNCTION"
end

class Function
  attr_reader :arity, :name

  def initialize(arity, name, type)
    @arity = arity
    @name = name
    @type = type
  end

  def as_json
    {
      type: :function,
      arity: @arity,
      name: @name,
    }
  end
end

class Compiler
  def initialize(statements, chunk, name = "__script__", type = FunctionType::SCRIPT, parameters = [])
    @statements = statements
    @chunk = chunk
    @name = name
    @type = type
    @function = Function.new(0, name, type)
  end

  def compile
    @statements.each do |statement|
      statement.accept(self)
    end

    emit_return

    @function
  end

  def add_constant(constant)
    @chunk.add_constant(@name, constant)
  end

  # statements
  def visit_expression_statement(expression_statement)
    expression_statement.expression.accept(self)
    emit(Opcodes::POP)
  end

  def visit_function_statement(function_statement)
    function = Compiler.new(
      function_statement.body,
      @chunk,
      function_statement.full_name,
      FunctionType::FUNCTION,
      function_statement.parameters.map(&:lexeme),
    ).compile

    emit_two(Opcodes::LOAD_CONSTANT, add_constant(function))

    if function_statement.allocation.global?
      constant_index = add_constant(function_statement.name.lexeme)
      emit_two(Opcodes::DEFINE_GLOBAL, constant_index)
    elsif function_statement.allocation.local?
    end
  end

  def visit_return_statement(return_statement)
    if return_statement.value
      return_statement.value.accept(self)
    else
      emit(Opcodes::NIL)
    end

    emit(Opcodes::RETURN)
  end

  def visit_print_statement(print_statement)
    print_statement.expression.accept(self)
    emit(Opcodes::PRINT)
  end

  def visit_var_statement(var_statement)
    if var_statement.initializer
      var_statement.initializer.accept(self)
    else
      emit(Opcodes::NIL)
    end

    if var_statement.allocation.global?
      emit_two(Opcodes::DEFINE_GLOBAL, add_constant(var_statement.name.lexeme))
    elsif var_statement.allocation.local?
    elsif var_statement.allocation.heap_allocated?
      emit_two(Opcodes::SET_HEAP, var_statement.allocation.slot)
    else
      fail
    end
  end

  def visit_block_statement(block_statement)
    begin_scope

    block_statement.statements.each do |statement|
      statement.accept(self)
    end

    # Cleanup
    end_scope

    # while @locals.any? && @locals.last.depth > @scope_depth
    #   emit(Opcodes::POP)
    #   @locals.pop
    # end
  end

  def visit_if_statement(if_statement)
    if_statement.condition.accept(self)

    else_jump_offset = emit_jump(Opcodes::JUMP_ON_FALSE)

    emit(Opcodes::POP) # pop condition when condition is truthy
    if_statement.then_branch.accept(self)

    exit_jump = emit_jump(Opcodes::JUMP)

    @chunk.patch_jump(@name, else_jump_offset)

    emit(Opcodes::POP) # pop condition when condition is falsy
    if_statement.else_branch&.accept(self)

    @chunk.patch_jump(@name, exit_jump)
  end

  def visit_while_statement; end
  def visit_class_statement; end

  # expressions
  def visit_assign(assign_expression)
    assign_expression.value.accept(self)

    if assign_expression.allocation.global?
      constant_index = add_constant(assign_expression.name.lexeme)
      emit_two(Opcodes::SET_GLOBAL, constant_index)
    elsif assign_expression.allocation.local?
      emit_two(Opcodes::SET_LOCAL, assign_expression.allocation.slot)
    elsif assign_expression.allocation.heap_allocated?
      fail
    else
      fail
    end
  end

  def visit_variable(variable_expression)
    if variable_expression.allocation.global?
      constant_index = add_constant(variable_expression.name.lexeme)
      emit_two(Opcodes::GET_GLOBAL, constant_index)
    elsif variable_expression.allocation.local?
      emit_two(Opcodes::GET_LOCAL, variable_expression.allocation.slot)
    elsif variable_expression.allocation.heap_allocated?
      emit_two(Opcodes::GET_HEAP, variable_expression.allocation.slot)
    else
      fail
    end
  end

  def visit_super_expression; end
  def visit_this_expression; end

  def visit_binary(binary_expression)
    binary_expression.left.accept(self)
    binary_expression.right.accept(self)
    emit(
      {
        '+' => Opcodes::ADD,
        '-' => Opcodes::SUBTRACT,
        '*' => Opcodes::MULTIPLY,
        '/' => Opcodes::DIVIDE,
      }[binary_expression.operator.lexeme]
    )
  end

  def visit_grouping; end

  def visit_literal(literal_expression)
    constant_index = add_constant(literal_expression.value)
    emit_two(Opcodes::LOAD_CONSTANT, constant_index)
  end

  def visit_logical(logical_expression)
    if logical_expression.operator.lexeme == "and"
      logical_expression.left.accept(self)
      short_circuit_exit = emit_jump(Opcodes::JUMP_ON_FALSE)
      emit(Opcodes::POP) # clean up the left since there's no short circuit
      logical_expression.right.accept(self)
      @chunk.patch_jump(@name, short_circuit_exit)
    elsif logical_expression.operator.lexeme == "or"
      logical_expression.left.accept(self)
      else_jump = emit_jump(Opcodes::JUMP_ON_FALSE)
      end_jump = emit_jump(Opcodes::JUMP)
      @chunk.patch_jump(@name, else_jump)
      emit(Opcodes::POP) # clean up the left since there's no short circuit
      logical_expression.right.accept(self)
      @chunk.patch_jump(@name, end_jump)
    else
      fail
    end
  end

  def visit_unary; end

  def visit_call(call_expression)
    call_expression.callee.accept(self)
    call_expression.arguments.each { |arg| arg.accept(self) }

    emit_two(Opcodes::CALL, call_expression.arguments.count)
  end

  def visit_get_expression; end
  def visit_set_expression; end

  def begin_scope
    @scope_depth += 1
  end

  def end_scope
    @scope_depth -= 1
  end

  def emit(opcode)
    @chunk.write(@name, opcode)
  end

  def emit_two(opcode, operand)
    emit(opcode)
    emit(operand)
  end

  def emit_jump(jump_opcode)
    emit(jump_opcode)
    emit(Chunk::PLACEHOLDER)
    emit(Chunk::PLACEHOLDER)

    @chunk.size(@name) - 2
  end

  def emit_return
    emit(Opcodes::NIL)
    emit(Opcodes::RETURN)
  end
end
