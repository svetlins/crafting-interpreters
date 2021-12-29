module StaticResolver
  class Allocation
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

    def kind = @kind
    def slot = @slot || fail

    def global? = kind == :global
    def local? = kind == :local
    def heap_allocated? = kind == :heap_allocated
  end

  class Phase2
    def initialize(error_reporter: nil)
      @function_scopes = ['global']
      @stack_frame = [0]
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

    def generate_next_slot
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
        function_statement.allocation.slot = generate_next_slot
      end

      @function_scopes << function_statement.name.lexeme

      function_statement.full_name = "__" + @function_scopes.join('__') + "__"

      previous_stack_frame = @stack_frame
      @stack_frame = [0]
      resolve(function_statement.body)
      @stack_frame = previous_stack_frame
      @function_scopes.pop
    end

    def visit_return_statement(return_statement)
      return_statement.value.accept(self)
    end

    def visit_print_statement(print_statement)
      print_statement.expression.accept(self);
    end

    def visit_var_statement(var_statement)
      if var_statement.allocation.local?
        var_statement.allocation.slot = generate_next_slot
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
      if_statement.else_branch.accept(self)
    end

    def visit_while_statement; end
    def visit_class_statement = fail

    ### Expressions
    def visit_assign(*); end
    def visit_variable(variable_expression); end
    def visit_super_expression; end
    def visit_this_expression; end
    def visit_binary; end
    def visit_grouping; end
    def visit_literal(*); end
    def visit_logical; end
    def visit_unary; end
    def visit_call; end
    def visit_get_expression; end
    def visit_set_expression; end
  end

  class Phase1
    class FunctionScope
      def initialize(enclosing, global: false)
        @global = global
        @enclosing = enclosing
        @scopes = [{}]
        @heap_allocated = {}
      end

      def begin_block
        @scopes << {}
      end

      def end_block
        @scopes.pop
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
        if @global && @scopes.size == 1
          return Allocation.global
        end

        local = find_local(name)

        return local if find_local(name)

        @enclosing.find_upvalue(name)
      end

      def find_local(name)
        @scopes.reverse.each do |scope|
          if scope.has_key?(name)
            return scope[name]
          end
        end

        return nil
      end

      def find_upvalue(name)
        local = find_local(name)

        if local
          local.kind = :heap_allocated
          return local
        end

        if @enclosing
          @enclosing.find_upvalue(name)
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
      elsif resolvable.statement?
        resolvable.accept(self)
      elsif resolvable.expression?
        resolvable.accept(self)
      else
        raise
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

    def resolve_local(expression, name)
      @scopes.reverse.each_with_index do |scope, index|
        depth = index

        if scope.has_key? name.lexeme
          expression.depth = depth
          expression.location = @scope_names.reverse[index]
          break
        end
      end
    end

    def resolve_function(function, type)
      # enclosing_function = @current_function
      # @current_function = type
      # begin_scope(function.name.lexeme)

      # function.parameters.each do |parameter|
      #   declare(parameter)
      #   define(parameter)
      # end

      # resolve(function.body)

      # end_scope

      # @current_function = enclosing_function

      resolve(function.body)
    end

    def error(token, message)
      if @error_reporter
        @error_reporter.report_static_analysis_error(token, message)
      end
    end

    def visit_block_statement(block_statement)
      @function_scopes.last.begin_block
      resolve(block_statement.statements)
      @function_scopes.last.end_block

      return nil
    end

    def visit_var_statement(var_statement)
      var_statement.allocation = @function_scopes.last.add_variable(var_statement.name.lexeme)

      # declare(var_statement.name)

      if var_statement.initializer
        resolve(var_statement.initializer)
      end

      # define(var_statement.name)

      return nil
    end

    def visit_variable(variable_expression)
      # if !@scopes.empty? && @scopes.last[variable_expression.name.lexeme] == false
      #   error(variable_expression.name, "Can't read local variable in its own initializer")
      # end

      # resolve_local(variable_expression, variable_expression.name)

      # return nil

      variable_expression.allocation =
        @function_scopes.last.resolve_variable(variable_expression.name.lexeme)

      return nil
    end

    def visit_assign(assign_expression)
      resolve(assign_expression.value)
      assign_expression.allocation =
        @function_scopes.last.resolve_variable(assign_expression.name.lexeme)

      return nil
    end

    def visit_function_statement(function_statement)
      # declare(function_statement.name)
      # define(function_statement.name)

      function_statement.allocation =
        @function_scopes.last.add_variable(function_statement.name.lexeme)

      @function_scopes << FunctionScope.new(@function_scopes.last)
      resolve(function_statement.body)
      # resolve_function(function_statement, FunctionTypes::FUNCTION)
      @function_scopes.pop

      return nil
    end

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

      if return_statement.value
        if @current_function == FunctionTypes::INITIALIZER
          error(return_statement.keyword, "Can't return value from initializer")
        end

        resolve(return_statement.value)
      end

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

    def visit_get_expression(get_expression)
      resolve(get_expression.object)

      return nil
    end

    def visit_set_expression(set_expression)
      resolve(set_expression.value)
      resolve(set_expression.object)

      return nil
    end


    def visit_grouping(grouping_expression)
      resolve(grouping_expression.expression)

      return nil
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

    def visit_literal(literal_expression); end

    def visit_this_expression(this_expression) = fail
    def visit_super_expression(super_expression) = fail
    def visit_class_statement(class_statement) = fail
  end
end
