module TreePrinter
  extend self

  def print(tree)
    regular_tree =
      if tree.is_a? Array
        tree.map { |resolvable_element| resolvable_element.accept(self) }
      elsif tree.statement?
        tree.accept(self)
      elsif tree.expression?
        tree.accept(self)
      else
        raise "Malformed tree"
      end

    {name: "Program", children: regular_tree}
  end

  def visit_expression_statement(expression_statement)
    {
      name: "expression_statement",
      children: [expression_statement.expression.accept(self)],
    }
  end

  def visit_function_statement(function_statement)
    {
      name: "function",
      attributes: {
        name: "#{function_statement.name.lexeme}(#{function_statement.parameters.map(&:lexeme).join(", ")})",
      },
      children: function_statement.body.map { |statement| statement.accept(self) }
    }
  end

  def visit_return_statement(return_statement)
    {
      name: "return",
      children: [return_statement.value.accept(self)],
    }
  end

  def visit_print_statement(print_statement)
    {
      name: "print_statement",
      children: [print_statement.expression.accept(self)],
    }
  end

  def visit_var_statement(variable_statement)
    {
      name: "var_statement",
      attributes: {
        name: variable_statement.name.lexeme,
      },
      children: [variable_statement.initializer&.accept(self)].compact
    }
  end

  def visit_block_statement(block_statement)
    {
      name: "block",
      children: block_statement.statements.map { |statement| statement.accept(self) }
    }
  end

  def visit_if_statement(if_statement)
    {
      name: "if",
      children: [
        if_statement.condition.accept(self),
        if_statement.then_branch.accept(self),
        if_statement.else_branch.accept(self),
      ],
    }
  end

  def visit_while_statement(statement); {name: "while_statement"} end

  def visit_class_statement(statement); {name: "class_statement"} end

  # ---------

  def visit_assign(assign_expression)
    {
      name: "assign",
      attributes: {
        name: assign_expression.name.lexeme,
      },
      children: [
        assign_expression.value.accept(self),
      ]
    }
  end

  def visit_binary(binary_expression)
    {
      name: "binary",
      attributes: {
        operator: binary_expression.operator.lexeme,
      },
      children: [binary_expression.left.accept(self), binary_expression.right.accept(self)]
    }
  end

  def visit_grouping(expression); {name: "expression"} end

  def visit_literal(literal_expression)
    {
      name: "literal",
      attributes: {
        value: literal_expression.value,
      }
    }
  end

  def visit_logical(expression); {name: "expression"} end

  def visit_unary(unary_expression)
    {
      name: "unary",
      attributes: {
        operator: unary_expression.operator.lexeme
      },
      children: [unary_expression.right.accept(self)]
    }
  end

  def visit_variable(variable_expression)
    {
      name: "variable lookup",
      attributes: {
        name: variable_expression.name.lexeme
      }
    }
  end

  def visit_call(call_expression)
    {
      name: "call_expression",
      children: [call_expression.callee.accept(self)] + call_expression.arguments.map { |argument| argument.accept(self) },
    }
  end

  def visit_get_expression(expression); {name: "expression"} end

  def visit_set_expression(expression); {name: "expression"} end

  def visit_super_expression(expression); {name: "expression"} end

  def visit_this_expression(expression); {name: "expression"} end
end
