module SexpPrinter
  extend self

  def print(expression)
    expression.accept(self)
  end

  def visit_binary(binary)
    parenthesize(binary.operator.lexeme, binary.left, binary.right)
  end

  def visit_grouping(grouping)
    parenthesize('group', grouping.expression)
  end

  def visit_literal(literal)
    return 'nil' if literal.value.nil?
    literal.value.to_s
  end

  def visit_unary(unary)
    parenthesize(unary.operator.lexeme, unary.right)
  end

  def parenthesize(name, *items)
    "(" + name + items.map { |item| " #{item.accept(self)}" }.join + ")"
  end
end
