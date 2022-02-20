module ALox
  class UpvalueCompiler
    class FunctionDescriptor
      attr_reader :arity, :name

      def initialize(name, arity, upvalues)
        @arity = arity
        @name = name
        @upvalues = upvalues
      end

      def upvalue_count
        @upvalues.count
      end

      def serialize
        {
          type: :function,
          arity: @arity,
          name: @name,
          upvalue_count: upvalue_count,
        }
      end
    end

    def initialize(statements, executable, name = "__toplevel__", arity = 0, upvalues = [], error_reporter: nil)
      @statements = statements
      @executable = executable
      @name = name
      @function = FunctionDescriptor.new(name, arity, upvalues)
      @error_reporter = error_reporter

      executable.reset_function(name)
    end

    def compile
      @statements.each do |statement|
        statement.accept(self)
      end

      emit_return

      @function
    end

    def add_constant(constant)
      @executable.add_constant(constant)
    end

    # statements
    def visit_expression_statement(expression_statement)
      expression_statement.expression.accept(self)
      emit(Opcodes::POP)
    end

    def visit_function_statement(function_statement)
      function = UpvalueCompiler.new(
        function_statement.body,
        @executable,
        function_statement.name.lexeme, # TODO: use full name again (dropped in Phase2)
        function_statement.parameters.count,
        function_statement.upvalues,
      ).compile

      emit_two(Opcodes::LOAD_CLOSURE, add_constant(function))

      function_statement.upvalues.each do |upvalue|
        emit_two(upvalue.local ? 1 : 0, upvalue.slot)
      end

      if function_statement.allocation.global?
        constant_index = add_constant(function_statement.name.lexeme)
        emit_two(Opcodes::DEFINE_GLOBAL, constant_index)
      elsif function_statement.allocation.local?
        # noop, it's on the stack
      end
    end

    def visit_return_statement(return_statement)
      if return_statement.value
        return_statement.value.accept(self)
      else
        emit(Opcodes::NIL_OP)
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
        emit(Opcodes::NIL_OP)
      end

      if var_statement.allocation.global?
        emit_two(Opcodes::DEFINE_GLOBAL, add_constant(var_statement.name.lexeme))
      elsif var_statement.allocation.local?
        # no-op, stack slot should match :fingers-crossed:
      else
        fail
      end
    end

    def visit_block_statement(block_statement)
      block_statement.statements.each do |statement|
        statement.accept(self)
      end

      block_statement.locals_count.times { emit(Opcodes::POP) }
    end

    def visit_if_statement(if_statement)
      if_statement.condition.accept(self)
      else_jump_offset = emit_jump(Opcodes::JUMP_ON_FALSE)

      emit(Opcodes::POP) # pop condition when condition is truthy
      if_statement.then_branch.accept(self)

      exit_jump = emit_jump(Opcodes::JUMP)

      @executable.patch_jump(@name, else_jump_offset)

      emit(Opcodes::POP) # pop condition when condition is falsy
      if_statement.else_branch&.accept(self)

      @executable.patch_jump(@name, exit_jump)
    end

    def visit_while_statement(while_statement)
      begin_loop_offset = @executable.functions[@name].size
      while_statement.condition.accept(self)
      exit_loop_offset = emit_jump(Opcodes::JUMP_ON_FALSE)
      emit(Opcodes::POP)
      while_statement.body.accept(self)
      emit(Opcodes::JUMP)
      emit_two(*BinaryUtils.pack_short(begin_loop_offset - 2 - @executable.functions[@name].size))
      @executable.patch_jump(@name, exit_loop_offset)
      emit(Opcodes::POP)
    end

    def visit_class_statement
    end

    def visit_assign(assign_expression)
      assign_expression.value.accept(self)

      if assign_expression.allocation.global?
        constant_index = add_constant(assign_expression.name.lexeme)
        emit_two(Opcodes::SET_GLOBAL, constant_index)
      elsif assign_expression.allocation.local?
        emit_two(Opcodes::SET_LOCAL, assign_expression.allocation.slot)
      elsif assign_expression.allocation.upvalue?
        emit_two(Opcodes::SET_UPVALUE, assign_expression.allocation.slot)
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
      elsif variable_expression.allocation.upvalue?
        emit_two(Opcodes::GET_UPVALUE, variable_expression.allocation.slot)
      else
        fail
      end
    end

    def visit_binary(binary_expression)
      binary_expression.left.accept(self)
      binary_expression.right.accept(self)

      {
        "+" => [Opcodes::ADD],
        "-" => [Opcodes::SUBTRACT],
        "*" => [Opcodes::MULTIPLY],
        "/" => [Opcodes::DIVIDE],
        "==" => [Opcodes::EQUAL],
        "!=" => [Opcodes::EQUAL, Opcodes::NOT],
        ">" => [Opcodes::GREATER],
        "<" => [Opcodes::LESSER],
        ">=" => [Opcodes::LESSER, Opcodes::NOT],
        "<=" => [Opcodes::GREATER, Opcodes::NOT]
      }.fetch(binary_expression.operator.lexeme).each { |op| emit(op) }
    end

    def visit_grouping(grouping_expression)
      grouping_expression.expression.accept(self)
    end

    def visit_literal(literal_expression)
      if literal_expression.value == true
        emit(Opcodes::TRUE_OP)
      elsif literal_expression.value == false
        emit(Opcodes::FALSE_OP)
      elsif literal_expression.value.nil?
        emit(Opcodes::NIL_OP)
      else
        constant_index = add_constant(literal_expression.value)
        emit_two(Opcodes::LOAD_CONSTANT, constant_index)
      end
    end

    def visit_logical(logical_expression)
      if logical_expression.operator.type == TokenTypes::AND
        logical_expression.left.accept(self)
        short_circuit_exit = emit_jump(Opcodes::JUMP_ON_FALSE)
        emit(Opcodes::POP) # clean up the left since there's no short circuit
        logical_expression.right.accept(self)
        @executable.patch_jump(@name, short_circuit_exit)
      elsif logical_expression.operator.type == TokenTypes::OR
        logical_expression.left.accept(self)
        else_jump = emit_jump(Opcodes::JUMP_ON_FALSE)
        end_jump = emit_jump(Opcodes::JUMP)
        @executable.patch_jump(@name, else_jump)
        emit(Opcodes::POP) # clean up the left since there's no short circuit
        logical_expression.right.accept(self)
        @executable.patch_jump(@name, end_jump)
      else
        fail
      end
    end

    def visit_unary(unary_expression)
      unary_expression.right.accept(self)

      {
        "-" => [Opcodes::NEGATE],
        "!" => [Opcodes::NOT]
      }.fetch(unary_expression.operator.lexeme).each { |op| emit(op) }
    end

    def visit_call(call_expression)
      call_expression.callee.accept(self)
      call_expression.arguments.each { |arg| arg.accept(self) }

      emit_two(Opcodes::CALL, call_expression.arguments.count)
    end

    def emit(opcode)
      @executable.write(@name, opcode)
    end

    def emit_two(opcode, operand)
      emit(opcode)
      emit(operand)
    end

    def emit_jump(jump_opcode)
      emit(jump_opcode)
      emit("PLACEHOLDER")
      emit("PLACEHOLDER")

      @executable.size(@name) - 2
    end

    def emit_return
      emit(Opcodes::NIL_OP)
      emit(Opcodes::RETURN)
    end
  end
end
