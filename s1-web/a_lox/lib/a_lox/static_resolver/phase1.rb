module ALox
  module StaticResolver
    class Allocation
      attr_reader :kind

      def self.global
        @_global ||= new(:global)
      end

      def initialize(kind)
        self.kind = kind
      end

      def kind=(kind)
        fail unless %i[global local heap_allocated].include? kind
        @kind = kind
      end

      def slot=(slot)
        fail unless local?
        @slot = slot
      end

      def slot
        return object_id if heap_allocated?
        @slot || fail
      end

      def stack_slot
        fail unless local?
        slot
      end

      def heap_slot
        fail unless heap_allocated?
        slot
      end

      def global?
        kind == :global
      end

      def local?
        kind == :local
      end

      def heap_allocated?
        kind == :heap_allocated
      end
    end

    class Phase1
      class FunctionScope
        attr_reader :heap_usages

        def initialize(enclosing, global: false)
          @global = global
          @enclosing = enclosing
          @scopes = [{}]
          @heap_allocated = []
          @heap_usages = []
        end

        def begin_block
          @scopes << {}
        end

        def end_block
          @scopes.pop
        end

        def global?
          @global
        end

        def heap_slots
          @heap_allocated
        end

        def add_variable(name)
          if @global && @scopes.size == 1
            return Allocation.global
          end

          allocation = Allocation.new(:local)
          @scopes.last[name] = allocation

          allocation
        end

        def resolve_variable(name)
          local = find_local(name)

          return local if find_local(name)

          if @enclosing
            on_the_heap = @enclosing.find_upvalue(name)
            @heap_usages << on_the_heap.slot if on_the_heap.heap_allocated?

            return on_the_heap
          end

          Allocation.global
        end

        def find_local(name)
          @scopes.reverse_each do |scope|
            if scope.has_key?(name)
              return scope[name]
            end
          end

          nil
        end

        def find_upvalue(name)
          local = find_local(name)

          if local
            local.kind = :heap_allocated
            @heap_allocated << local.slot
            return local
          end

          if @enclosing
            allocation = @enclosing.find_upvalue(name)
            @heap_usages << allocation.slot if allocation.heap_allocated?
            allocation
          else
            Allocation.global
          end
        end
      end

      def initialize(error_reporter: nil)
        @function_scopes = [FunctionScope.new(nil, global: true)]
        @error_reporter = error_reporter
      end

      def resolve(resolvable)
        if resolvable.is_a? Array
          resolvable.each { |resolvable_element| resolve(resolvable_element) }
        else
          resolvable.accept(self)
        end
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

      def error(token, message)
        @error_reporter&.report_static_analysis_error(token, message)
      end

      def visit_block_statement(block_statement)
        @function_scopes.last.begin_block
        resolve(block_statement.statements)
        block_statement.locals_count = @function_scopes.last.end_block.size

        nil
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
        # declare(function_statement.name)
        # define(function_statement.name)

        function_statement.allocation =
          @function_scopes.last.add_variable(function_statement.name.lexeme)

        @function_scopes << FunctionScope.new(@function_scopes.last)

        function_statement.parameter_allocations =
          function_statement.parameters.map do |parameter|
            @function_scopes.last.add_variable(parameter.lexeme)
          end

        resolve(function_statement.body)
        function_statement.heap_slots = @function_scopes.last.heap_slots
        function_statement.heap_usages = @function_scopes.last.heap_usages
        @function_scopes.pop

        nil
      end

      def visit_expression_statement(expression_statement)
        resolve(expression_statement.expression)

        nil
      end

      def visit_if_statement(if_statement)
        resolve(if_statement.condition)
        resolve(if_statement.then_branch)
        resolve(if_statement.else_branch) if if_statement.else_branch

        nil
      end

      def visit_print_statement(print_statement)
        resolve(print_statement.expression)

        nil
      end

      def visit_return_statement(return_statement)
        if @function_scopes.last.global?
          error(return_statement.keyword, "Can't return outside of function")
        end

        if return_statement.value
          # if ~initializer~
          #   error(return_statement.keyword, "Can't return value from initializer")
          # end

          resolve(return_statement.value)
        end

        nil
      end

      def visit_while_statement(while_statement)
        resolve(while_statement.condition)
        resolve(while_statement.body)

        nil
      end

      def visit_binary(binary_expression)
        resolve(binary_expression.left)
        resolve(binary_expression.right)

        nil
      end

      def visit_call(call_expression)
        resolve(call_expression.callee)
        call_expression.arguments.each do |argument|
          resolve(argument)
        end

        nil
      end

      def visit_get_expression(get_expression)
        resolve(get_expression.object)

        nil
      end

      def visit_set_expression(set_expression)
        resolve(set_expression.value)
        resolve(set_expression.object)

        nil
      end

      def visit_grouping(grouping_expression)
        resolve(grouping_expression.expression)

        nil
      end

      def visit_logical(logical_expression)
        resolve(logical_expression.left)
        resolve(logical_expression.right)

        nil
      end

      def visit_unary(unary_expression)
        resolve(unary_expression.right)

        nil
      end

      def visit_literal(literal_expression)
      end

      def visit_this_expression(this_expression) = fail

      def visit_super_expression(super_expression) = fail

      def visit_class_statement(class_statement) = fail
    end
  end
end
