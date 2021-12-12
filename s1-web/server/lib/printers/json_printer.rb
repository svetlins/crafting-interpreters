module JSONPrinter
  extend self

  def print(tree)
    if tree.is_a? Array
      tree.map { |resolvable_element| print(resolvable_element) }
    elsif tree.statement?
      tree.accept(self)
    elsif tree.expression?
      tree.accept(self)
    else
      raise "Malformed tree"
    end
  end

  def visit_expression_statement(expression_statement)
    expression_statement.expression.accept(self)
  end

  def visit_binary(binary)
    {
      left: binary.left.accept(self),
      operator: binary.operator.as_json,
      right: binary.right.accept(self),
    }
    # binary.left.accept(self) + binary.operator.lexeme + binary.right.accept(self)
  end

  def visit_grouping(grouping)
    "(" + grouping.expression.accept(self) + ")"
  end

  def visit_literal(literal)
    literal.value.inspect
  end

  def visit_unary(unary)
    unary.operator.lexeme + unary.right.accept(self)
  end
end
