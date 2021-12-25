require 'chunk'

class Compiler
  def initialize(statements)
    @statements = statements
    @chunk = Chunk.new
  end

  def compile
    @statements.each do |statement|
      statement.accept(self)
    end

    @chunk
  end

  # statements
  def visit_expression_statement(expression_statement)
    expression_statement.expression.accept(self)
    emit(Opcodes::POP)
  end

  def visit_function_statement; end
  def visit_return_statement; end

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

    constant_index = @chunk.add_constant(var_statement.name.lexeme)
    emit_two(Opcodes::DEFINE_GLOBAL, constant_index)
  end

  def visit_block_statement; end
  def visit_if_statement; end
  def visit_while_statement; end
  def visit_class_statement; end

  # expressions
  def visit_assign(assign_expression)
    assign_expression.value.accept(self)
    constant_index = @chunk.add_constant(assign_expression.name.lexeme)
    emit_two(Opcodes::SET_GLOBAL, constant_index)
  end

  def visit_variable(variable_expression)
    constant_index = @chunk.add_constant(variable_expression.name.lexeme)
    emit_two(Opcodes::GET_GLOBAL, constant_index)
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
    constant_index = @chunk.add_constant(literal_expression.value)
    emit_two(Opcodes::LOAD_CONSTANT, constant_index)
  end

  def visit_logical; end
  def visit_unary; end
  def visit_call; end
  def visit_get_expression; end
  def visit_set_expression; end

  def emit(opcode)
    @chunk.write(opcode)
  end

  def emit_two(opcode, operand)
    @chunk.write(opcode)
    @chunk.write(operand)
  end
end
