require 'scanner'

module Expression
  def self.define_expression_type(name, *fields)
    Struct.new(*fields) do
      define_method :accept do |visitor|
        visitor.public_send(:"visit_#{name.downcase}", self)
      end
    end
  end

  Binary = define_expression_type('Binary', :left, :operator, :right)
  Grouping = define_expression_type('Grouping', :expression)
  Literal = define_expression_type('Literal', :value)
  Unary = define_expression_type('Unary', :operator, :right)

  # Usage of visitor operations
  # an_expression = Binary.new(
  #   Grouping.new(
  #     Binary.new(
  #       Literal.new(1),
  #       Token.new(TokenTypes::PLUS, "+", nil, 1),
  #       Literal.new(2)
  #     )
  #   ),
  #   Token.new(TokenTypes::STAR, "*", nil, 1),
  #   Grouping.new(
  #     Binary.new(
  #       Literal.new(4),
  #       Token.new(TokenTypes::MINUS, "-", nil, 1),
  #       Literal.new(3)
  #     )
  #   ),
  # )

  # puts an_expression.accept(BadPrinter.new)
  # puts an_expression.accept(SexpPrinter.new)
  # puts an_expression.accept(RPNPrinter.new)

  class BadPrinter
    def visit_binary(binary)
      "(" + binary.left.accept(self) + binary.operator.lexeme + binary.right.accept(self) + ")"
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

  class SexpPrinter
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

  class RPNPrinter
    def visit_binary(binary)
      push(binary.operator.lexeme, binary.right, binary.left)
    end

    def visit_literal(literal)
      push(literal.value.to_s)
    end

    def visit_unary(unary)
      push(unary.operator.lexeme, unary.right)
    end

    def visit_grouping(grouping)
      grouping.expression.accept(self)
    end

    private def push(operator, *operands)
      stack = []
      stack.unshift(operator)

      operands.each do |operand|
        stack.unshift(operand.accept(self))
      end

      stack.join(" ")
    end
  end
end


