require 'chunk'

module FunctionType
  SCRIPT = "SCRIPT"
  FUNCTION = "FUNCTION"
end

class Function
  attr_reader :arity, :name, :chunk

  def initialize(arity, name, type)
    @arity = arity
    @name = name
    @type = type
    @chunk = Chunk.new
  end

  def as_json
    {
      arity: @arity,
      name: @name,
      chunk: @chunk.as_json,
    }
  end
end

class Compiler
  Local = Struct.new(:name, :depth)

  attr_reader :locals

  def initialize(statements, type = FunctionType::SCRIPT, parameters = [], enclosing = nil)
    @statements = statements
    @type = type
    @enclosing = enclosing
    @function = Function.new(0, type, type)
    @locals = [Local.new('', 0)]
    @scope_depth = 0

    if type == FunctionType::FUNCTION
      begin_scope

      parameters.each do |parameter|
        add_local(parameter)
      end
    end
  end

  def compile
    @statements.each do |statement|
      statement.accept(self)
    end

    emit_return

    @function
  end

  # statements
  def visit_expression_statement(expression_statement)
    expression_statement.expression.accept(self)
    emit(Opcodes::POP)
  end

  def visit_function_statement(function_statement)
    if @scope_depth > 0
      add_local(function_statement.name.lexeme)
    end

    function = Compiler.new(
      function_statement.body,
      FunctionType::FUNCTION,
      function_statement.parameters.map(&:lexeme),
      self
    ).compile

    emit_two(Opcodes::LOAD_CONSTANT, @function.chunk.add_constant(function))

    if @scope_depth == 0
      constant_index = @function.chunk.add_constant(function_statement.name.lexeme)
      emit_two(Opcodes::DEFINE_GLOBAL, constant_index)
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

    if @scope_depth > 0
      add_local(var_statement.name.lexeme)
    else # global
      constant_index = @function.chunk.add_constant(var_statement.name.lexeme)
      emit_two(Opcodes::DEFINE_GLOBAL, constant_index)
    end
  end

  def visit_block_statement(block_statement)
    begin_scope

    block_statement.statements.each do |statement|
      statement.accept(self)
    end

    # Cleanup
    end_scope

    while @locals.any? && @locals.last.depth > @scope_depth
      emit(Opcodes::POP)
      @locals.pop
    end
  end

  def visit_if_statement(if_statement)
    if_statement.condition.accept(self)

    else_jump_offset = emit_jump(Opcodes::JUMP_ON_FALSE)

    emit(Opcodes::POP) # pop condition when condition is truthy
    if_statement.then_branch.accept(self)

    exit_jump = emit_jump(Opcodes::JUMP)

    @function.chunk.patch_jump(else_jump_offset)

    emit(Opcodes::POP) # pop condition when condition is falsy
    if_statement.else_branch&.accept(self)

    @function.chunk.patch_jump(exit_jump)
  end

  def visit_while_statement; end
  def visit_class_statement; end

  # expressions
  def visit_assign(assign_expression)
    assign_expression.value.accept(self)

    stack_slot = resolve_local(assign_expression.name.lexeme)

    if stack_slot
      emit_two(Opcodes::SET_LOCAL, stack_slot)
    else
      constant_index = @function.chunk.add_constant(assign_expression.name.lexeme)
      emit_two(Opcodes::SET_GLOBAL, constant_index)
    end
  end

  def visit_variable(variable_expression)
    stack_slot = resolve_local(variable_expression.name.lexeme)

    if stack_slot
      emit_two(Opcodes::GET_LOCAL, stack_slot)
    else
      constant_index = @function.chunk.add_constant(variable_expression.name.lexeme)
      emit_two(Opcodes::GET_GLOBAL, constant_index)
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
    constant_index = @function.chunk.add_constant(literal_expression.value)
    emit_two(Opcodes::LOAD_CONSTANT, constant_index)
  end

  def visit_logical(logical_expression)
    if logical_expression.operator.lexeme == "and"
      logical_expression.left.accept(self)
      short_circuit_exit = emit_jump(Opcodes::JUMP_ON_FALSE)
      emit(Opcodes::POP) # clean up the left since there's no short circuit
      logical_expression.right.accept(self)
      @function.chunk.patch_jump(short_circuit_exit)
    elsif logical_expression.operator.lexeme == "or"
      logical_expression.left.accept(self)
      else_jump = emit_jump(Opcodes::JUMP_ON_FALSE)
      end_jump = emit_jump(Opcodes::JUMP)
      @function.chunk.patch_jump(else_jump)
      emit(Opcodes::POP) # clean up the left since there's no short circuit
      logical_expression.right.accept(self)
      @function.chunk.patch_jump(end_jump)
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
    @function.chunk.write(opcode)
  end

  def emit_two(opcode, operand)
    emit(opcode)
    emit(operand)
  end

  def emit_jump(jump_opcode)
    emit(jump_opcode)
    emit(Chunk::PLACEHOLDER)
    emit(Chunk::PLACEHOLDER)

    @function.chunk.size - 2
  end

  def emit_return
    emit(Opcodes::NIL)
    emit(Opcodes::RETURN)
  end

  def add_local(name)
    @locals << Local.new(name, @scope_depth)
  end

  def resolve_local(name)
    _local, stack_slot = @locals.each_with_index.to_a.reverse.detect { |local, i| local.name == name }

    stack_slot
  end
end
