class TreePrinter
  def initialize(statements)
    @statements = statements
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
      children: [expression_statement.expression.accept(self)],
    }
  end

  def visit_function_statement(function_statement)
    {
      name: "FUN-DEF",
      attributes: {
        name: "#{function_statement.name.lexeme}(#{function_statement.parameters.map(&:lexeme).join(", ")})",
      },
      children: function_statement.body.map { |statement| statement.accept(self) }
    }
  end

  def visit_return_statement(return_statement)
    {
      name: "RETURN",
      attributes: {},
      children: [return_statement.value.accept(self)],
    }
  end

  def visit_print_statement(print_statement)
    {
      name: "PRINT",
      attributes: {},
      children: [print_statement.expression.accept(self)],
    }
  end

  def visit_var_statement(variable_statement)
    {
      name: "VAR-DEF",
      attributes: {
        name: variable_statement.name.lexeme,
      },
      children: [variable_statement.initializer&.accept(self)].compact
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
        adorn(if_statement.else_branch&.accept(self), "ELSE"),
      ].compact,
    }
  end

  def visit_while_statement(statement); {name: "WHILE", attributes: {}} end

  def visit_class_statement(statement); {name: "CLASS", attributes: {}} end

  # ---------

  def visit_assign(assign_expression)
    {
      name: "ASSIGN",
      attributes: {
        name: assign_expression.name.lexeme,
      }.merge(scope_attributes(assign_expression)),
      children: [
        assign_expression.value.accept(self),
      ]
    }
  end

  def visit_binary(binary_expression)
    {
      name: "BINARY_EXP",
      attributes: {
        operator: binary_expression.operator.lexeme,
      },
      children: [binary_expression.left.accept(self), binary_expression.right.accept(self)]
    }
  end

  def visit_grouping(expression); {name: "GROUP", attributes: {}} end

  def visit_literal(literal_expression)
    {
      name: "LITERAL",
      attributes: {
        value: literal_expression.value.inspect,
      }
    }
  end

  def visit_logical(expression); {name: "LOGICAL", attributes: {}} end

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
        adorn(call_expression.callee.accept(self), "CALLEE"),
      ] + call_expression.arguments.map { |argument| argument.accept(self) },
    }
  end

  def visit_get_expression(expression); {name: "GET", attributes: {}}; end

  def visit_set_expression(expression); {name: "SET", attributes: {}}; end

  def visit_super_expression(expression); {name: "SUPER", attributes: {}}; end

  def visit_this_expression(expression); {name: "THIS", attributes: {}}; end

  private

  def adorn(node, role)
    return unless node

    node.tap do
      node[:attributes][:role] = role
    end
  end

  def scope_attributes(expression)
    if expression.depth.nil?
      {scope: "GLOBAL"}
    elsif expression.depth.zero?
      {scope: "LOCAL"}
    elsif expression.depth.nonzero?
      {
        scope: "CLOSURE",
        closure: expression.location,
      }
    end
  end
end
