module ALox
  module Printers
    class ReactTreePrinter
      def initialize(statements)
        @statements = statements
        @function_stack = []
      end

      def print
        regular_tree =
          if @statements.is_a? Array
            @statements.map { |resolvable_element| resolvable_element.accept(self) }
          elsif @statements.statement?
            @statements.accept(self)
          elsif @statements.expression?
            @statements.accept(self)
          else
            raise "Malformed tree"
          end

        {name: "PROGRAM", children: regular_tree}
      end

      def visit_expression_statement(expression_statement)
        {
          name: "EXP-STMT",
          attributes: {},
          children: [expression_statement.expression.accept(self)]
        }
      end

      def visit_function_statement(function_statement)
        @function_stack << function_statement

        function_node = {
          name: "FUN-DEF",
          attributes: output_upvalues(
            {
              name: "#{function_statement.name.lexeme}(#{function_statement.parameters.map(&:lexeme).join(", ")})",
            },
            function_statement,
          ),
          children: function_statement.body.map { |statement| statement.accept(self) }
        }

        @function_stack.pop

        function_node
      end

      def visit_return_statement(return_statement)
        {
          name: "RETURN",
          attributes: {},
          children: [return_statement.value.accept(self)]
        }
      end

      def visit_print_statement(print_statement)
        {
          name: "PRINT",
          attributes: {},
          children: [print_statement.expression.accept(self)]
        }
      end

      def visit_var_statement(variable_statement)
        {
          name: "VAR-DEF",
          attributes: {
            name: variable_statement.name.lexeme
          }.merge(scope_attributes(variable_statement)),
          children: [adorn(variable_statement.initializer&.accept(self), "INITIALIZER")].compact
        }
      end

      def visit_block_statement(block_statement)
        {
          name: "BLOCK",
          attributes: {},
          children: block_statement.statements.map { |statement| statement.accept(self) }
        }
      end

      def visit_if_statement(if_statement)
        {
          name: "IF",
          attributes: {},
          children: [
            adorn(if_statement.condition.accept(self), "CONDITION"),
            adorn(if_statement.then_branch.accept(self), "THEN"),
            adorn(if_statement.else_branch&.accept(self), "ELSE")
          ].compact
        }
      end

      def visit_while_statement(while_statement)
        {
          name: "WHILE",
          attributes: {},
          children: [
            adorn(while_statement.condition.accept(self), "CONDITION"),
            adorn(while_statement.body.accept(self), "BODY")
          ]
        }
      end

      # ---------

      def visit_assign(assign_expression)
        {
          name: "ASSIGN",
          attributes: {
            name: assign_expression.name.lexeme
          }.merge(scope_attributes(assign_expression)),
          children: [
            assign_expression.value.accept(self)
          ]
        }
      end

      def visit_binary(binary_expression)
        {
          name: "BINARY",
          attributes: {
            operator: binary_expression.operator.lexeme
          },
          children: [
            binary_expression.left.accept(self),
            binary_expression.right.accept(self)
          ]
        }
      end

      def visit_grouping(grouping_expression)
        {
          name: "GROUP",
          children: [grouping_expression.expression.accept(self)]
        }
      end

      def visit_literal(literal_expression)
        {
          name: "LITERAL",
          attributes: {
            value: literal_expression.value.inspect
          }
        }
      end

      def visit_logical(logical_expression)
        {
          name: "LOGICAL",
          attributes: {value: logical_expression.operator.lexeme},
          children: [
            logical_expression.left.accept(self),
            logical_expression.right.accept(self)
          ]
        }
      end

      def visit_unary(unary_expression)
        {
          name: "UNARY",
          attributes: {
            operator: unary_expression.operator.lexeme
          },
          children: [unary_expression.right.accept(self)]
        }
      end

      def visit_variable(variable_expression)
        {
          name: "VAR-LOOKUP",
          attributes: {
            name: variable_expression.name.lexeme
          }.merge(scope_attributes(variable_expression))
        }
      end

      def visit_call(call_expression)
        {
          name: "CALL",
          attributes: {},
          children: [
            adorn(call_expression.callee.accept(self), "CALLEE")
          ] + call_expression.arguments.map { |argument| adorn(argument.accept(self), "ARG") }
        }
      end

      private

      def adorn(node, role)
        return unless node

        node.tap do
          node[:attributes][:role] = role
        end
      end

      def output_upvalues(attributes, function_statement)
        if function_statement.upvalues.any?
          attributes.merge(
            upvalues: function_statement.upvalues.map { "#{_1.slot}:#{_1.local}" }.join(", ")
          )
        else
          attributes
        end
      end

      def scope_attributes(node)
        if node.allocation.global?
          {allocation: "GLOBAL"}
        elsif node.allocation.local?
          {
            :allocation => "STACK",
            "stack slot" => node.allocation.slot
          }
        elsif node.allocation.upvalue?
          upvalue = @function_stack.last.upvalues[node.allocation.slot]
          {
            allocation: "UPVALUE",
            variable_slot: node.allocation.slot,
            upvalue_slot: upvalue.slot,
            upvalue_local: upvalue.local
          }
        end
      end
    end
  end
end
