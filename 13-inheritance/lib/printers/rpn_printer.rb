module RPNPrinter
  extend self

  def print(expression)
    expression.accept(self)
  end

  def visit_binary(binary)
    rpn(binary.operator.lexeme, binary.right, binary.left)
  end

  def visit_literal(literal)
    rpn(literal.value.to_s)
  end

  def visit_unary(unary)
    rpn(unary.operator.lexeme, unary.right)
  end

  def visit_grouping(grouping)
    grouping.expression.accept(self)
  end

  private def rpn(operator, *operands)
    ([operator] + operands.map { |operand| operand.accept(self) }).reverse.join(' ')
  end
end
