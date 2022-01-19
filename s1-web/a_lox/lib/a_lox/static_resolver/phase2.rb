module ALox
  module StaticResolver
    class Phase2
      def initialize(error_reporter: nil)
        @function_scopes = ["global"]
        @stack_frame = [0]
        @error_reporter = error_reporter
      end

      def resolve(resolvable)
        if resolvable.is_a? Array
          resolvable.each { |resolvable_element| resolve(resolvable_element) }
        else
          resolvable.accept(self)
        end
      end

      def generate_next_stack_slot
        next_slot = @stack_frame.last
        @stack_frame[-1] = @stack_frame.last + 1

        next_slot
      end

      ### Statements
      def visit_expression_statement(expression_statement)
        expression_statement.expression.accept(self)
      end

      def visit_function_statement(function_statement)
        if function_statement.allocation.local?
          function_statement.allocation.stack_slot = generate_next_stack_slot
        end

        @function_scopes << function_statement.name.lexeme

        function_statement.full_name = "__" + @function_scopes.join("__") + "__"

        previous_stack_frame = @stack_frame
        @stack_frame = [0]

        function_statement.parameter_allocations.each do |parameter_allocation|
          parameter_allocation.stack_slot = generate_next_stack_slot
        end

        resolve(function_statement.body)
        @stack_frame = previous_stack_frame
        @function_scopes.pop
      end

      def visit_return_statement(return_statement)
        return_statement.value.accept(self)
      end

      def visit_print_statement(print_statement)
        print_statement.expression.accept(self)
      end

      def visit_var_statement(var_statement)
        if var_statement.allocation.local?
          var_statement.allocation.stack_slot = generate_next_stack_slot
        end
      end

      def visit_block_statement(block_statement)
        @stack_frame << @stack_frame.last
        resolve(block_statement.statements)
        @stack_frame.pop
      end

      def visit_if_statement(if_statement)
        if_statement.condition.accept(self)
        if_statement.then_branch.accept(self)
        if_statement.else_branch&.accept(self)
      end

      def visit_while_statement(while_statement)
        while_statement.condition.accept(self)
        while_statement.body.accept(self)
      end

      ### Expressions
      def visit_assign(*)
      end

      def visit_variable(*)
      end

      def visit_binary(binary_expression)
      end

      def visit_grouping(grouping_expression)
      end

      def visit_literal(*)
      end

      def visit_logical
      end

      def visit_unary(unary_expression)
      end

      def visit_call(call_expression)
      end
    end
  end
end
