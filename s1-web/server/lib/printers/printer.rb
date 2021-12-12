module Printer
  extend self

  def print(expression)
    expression.accept(self)
  end

  def visit_binary(binary)
    binary.left.accept(self) + binary.operator.lexeme + binary.right.accept(self)
  end

  def visit_grouping(grouping)
    "(" + grouping.expression.accept(self) + ")"
  end

  def visit_literal(literal)
    literal.value.to_s
  end

  def visit_unary(unary)
    unary.operator.lexeme + unary.right.accept(self)
  end
end
