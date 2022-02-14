module ALox
  module StaticResolver
    class Upvalues
      Allocation = Struct.new(:name, :kind, :slot) do
        def self.global; new(nil, :global, nil); end
        def self.local(name:, slot:); new(name, :local, slot); end
        def global?; kind == :global; end
      end

      class FunctionScope
        def initialize(enclosing: nil)
          @enclosing = enclosing
          @blocks = [[]]
          @upvalues = []
        end

        def top_level?
          @enclosing.nil?
        end

        def begin_block
          @blocks << []
        end

        def end_block
          @blocks.pop
        end

        def current_block
          @blocks.last
        end

        def heap_slots
          @heap_allocated
        end

        def add_variable(name)
          return Allocation.global if top_level? && @blocks.size == 1

          allocation = Allocation.local(name: name, slot: @blocks.flatten.count)

          @blocks.last << allocation

          allocation
        end

        def resolve_variable(name)
          local = find_local(name)

          return local if find_local(name)

          Allocation.global
        end

        def find_local(name)
          @blocks.reverse_each do |block|
            local = block.detect { |variable| variable.name == name }
            return local if local
          end

          nil
        end
      end

      def initialize(error_reporter: nil)
        @function_scopes = [FunctionScope.new]
        @error_reporter = error_reporter
      end

      def resolve(resolvable)
        if resolvable.is_a? Array
          resolvable.each { |resolvable_element| resolve(resolvable_element) }
        else
          resolvable.accept(self)
        end
      end

      def error(token, message)
        @error_reporter&.report_static_analysis_error(token, message)
      end

      def visit_block_statement(block_statement)
        @function_scopes.last.begin_block
        resolve(block_statement.statements)
        block_statement.locals_count = @function_scopes.last.end_block.size
      end

      def visit_var_statement(var_statement)
        var_statement.allocation = @function_scopes.last.add_variable(var_statement.name.lexeme)

        if var_statement.initializer
          resolve(var_statement.initializer)
        end
      end

      def visit_variable(variable_expression)
        variable_expression.allocation =
          @function_scopes.last.resolve_variable(variable_expression.name.lexeme)
      end

      def visit_assign(assign_expression)
        resolve(assign_expression.value)
        assign_expression.allocation =
          @function_scopes.last.resolve_variable(assign_expression.name.lexeme)
      end

      def visit_function_statement(function_statement)
        function_statement.allocation =
          @function_scopes.last.add_variable(function_statement.name.lexeme)

        @function_scopes << FunctionScope.new(enclosing: @function_scopes.last)

        function_statement.parameter_allocations =
          function_statement.parameters.map do |parameter|
            @function_scopes.last.add_variable(parameter.lexeme)
          end

        resolve(function_statement.body)

        @function_scopes.pop
      end

      def visit_expression_statement(expression_statement)
        resolve(expression_statement.expression)
      end

      def visit_if_statement(if_statement)
        resolve(if_statement.condition)
        resolve(if_statement.then_branch)
        resolve(if_statement.else_branch) if if_statement.else_branch
      end

      def visit_print_statement(print_statement)
        resolve(print_statement.expression)
      end

      def visit_return_statement(return_statement)
        if @function_scopes.last.top_level?
          error(return_statement.keyword, "Can't return outside of function")
        end

        if return_statement.value
          resolve(return_statement.value)
        end
      end

      def visit_while_statement(while_statement)
        resolve(while_statement.condition)
        resolve(while_statement.body)
      end

      def visit_binary(binary_expression)
        resolve(binary_expression.left)
        resolve(binary_expression.right)
      end

      def visit_call(call_expression)
        resolve(call_expression.callee)
        call_expression.arguments.each do |argument|
          resolve(argument)
        end
      end

      def visit_grouping(grouping_expression)
        resolve(grouping_expression.expression)
      end

      def visit_logical(logical_expression)
        resolve(logical_expression.left)
        resolve(logical_expression.right)
      end

      def visit_unary(unary_expression)
        resolve(unary_expression.right)
      end

      def visit_literal(literal_expression)
      end
    end
  end
end
