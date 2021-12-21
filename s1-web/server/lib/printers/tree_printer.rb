class TreePrinter
  def initialize(tree, static_resolutions)
    @tree, @static_resolutions = tree, static_resolutions
  end

  def print
    regular_tree =
      if @tree.is_a? Array
        @tree.map { |resolvable_element| resolvable_element.accept(self) }
      elsif @tree.statement?
        @tree.accept(self)
      elsif @tree.expression?
        @tree.accept(self)
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
        if_statement.condition.accept(self).tap { |cond| cond[:attributes][:role] = "condition" },
        if_statement.then_branch.accept(self).tap { |then_branch| then_branch[:attributes][:role] = "then_branch" },
        if_statement.else_branch.accept(self).tap { |else_branch| else_branch[:attributes][:role] = "else_branch" },
      ],
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
      },
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
        value: literal_expression.value,
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
        depth: @static_resolutions[variable_expression.object_id] || 'Global',
        name: variable_expression.name.lexeme
      }
    }
  end

  def visit_call(call_expression)
    {
      name: "CALL",
      attributes: {},
      children: [
        call_expression.callee.accept(self).tap { |callee| callee[:attributes][:role] = "callee" },
      ] + call_expression.arguments.map { |argument| argument.accept(self) },
    }
  end

  def visit_get_expression(expression); {name: "GET", attributes: {}} end

  def visit_set_expression(expression); {name: "SET", attributes: {}} end

  def visit_super_expression(expression); {name: "SUPER", attributes: {}} end

  def visit_this_expression(expression); {name: "THIS", attributes: {}} end
end
