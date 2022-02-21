module ALox
  module StaticResolver
    class Upvalues
      Variable = Struct.new(:name, :kind, :slot, :depth) do
        attr_accessor :captured
        def self.global = new(nil, :global, nil)
        def self.local(name:, slot:, depth:) = new(name, :local, slot, depth)
        def self.upvalue(name:, slot:) = new(name, :upvalue, slot, nil)

        def global? = kind == :global
        def local? = kind == :local
        def upvalue? = kind == :upvalue
      end

      Upvalue = Struct.new(:slot, :local)

      class FunctionScope
        attr_reader :upvalues, :name

        def initialize(name, enclosing: nil)
          @name = name
          @enclosing = enclosing
          @locals = []
          @current_depth = 0
          @upvalues = []
        end

        def top_level?
          @enclosing.nil?
        end

        def begin_block
          @current_depth += 1
        end

        def end_block
          @current_depth -= 1

          block_variables = @locals.select { _1.depth > @current_depth }

          @locals.reject! { _1.depth > @current_depth }

          block_variables
        end

        def add_variable(name)
          return Variable.global if top_level? && @current_depth == 0

          variable = Variable.local(name: name, slot: @locals.count, depth: @current_depth)

          @locals << variable

          variable
        end

        # fn outer(x, y)
        #   fn middle [1, true]
        #     fn inner [0, false]
        #       return y
        def resolve_variable(name)
          local = find_local(name)

          return local if local

          if @enclosing # ? maybe not needed to if
            upvalue_slot, is_local = @enclosing.find_upvalue(name)

            if upvalue_slot
              upvalue_index = add_upvalue(upvalue_slot, local: is_local)

              return Variable.upvalue(name: name, slot: upvalue_index)
            end
          end

          Variable.global
        end

        def find_local(name)
          @locals.detect { |local| local.name == name }
        end

        def find_upvalue(name)
          local = find_local(name)

          if local
            local.captured = true
            return [local.slot, true]
          end

          if @enclosing
            up_upvalue_slot, is_local = @enclosing.find_upvalue(name)

            if up_upvalue_slot
              xxx_slot = add_upvalue(up_upvalue_slot, local: is_local)

              return [xxx_slot, false]
            end
          end

          [nil, false]
        end

        def add_upvalue(upvalue, local:)
          new_upvalue = Upvalue.new(upvalue, local)

          @upvalues.each_with_index do |upvalue, index|
            return index if upvalue == new_upvalue
          end

          @upvalues << new_upvalue

          @upvalues.count - 1
        end
      end

      def initialize(error_reporter: nil)
        @function_scopes = [FunctionScope.new('global')]
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
        block_statement.locals = @function_scopes.last.end_block
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

        @function_scopes << FunctionScope.new(
          function_statement.name.lexeme,
          enclosing: @function_scopes.last
        )

        function_statement.parameters.map do |parameter|
          @function_scopes.last.add_variable(parameter.lexeme)
        end

        resolve(function_statement.body)

        function_statement.upvalues = @function_scopes.last.upvalues
        function_statement.full_name = '__' + @function_scopes.map(&:name).join('__') + '__'

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
