require 'irb'

require 'scanner'
require 'expression'
require 'parser'

module Lab
  include TokenTypes
  include Expression

  extend self

  class BadPrinter
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
      ([operator] + operands.map { |operand| operand.accept(self) }).reverse.join(' ')
    end
  end

  def run
    IRB.setup nil
    IRB.conf[:MAIN_CONTEXT] = IRB::Irb.new.context
    require 'irb/ext/multi-irb'
    IRB.irb nil, self
  end

  def scan(source)
    Scanner.new(source).scan
  end

  def parse(source)
    Parser.new(scan(source)).parse_expression
  end

  def sample_source1
    "1 + 2 * 3"
  end

  def sample_source2
    "(1 + 2) * 3"
  end

  def sample_expression1
    Binary.new(
      Grouping.new(
        Binary.new(
          Literal.new(1),
          Token.new(TokenTypes::PLUS, "+", nil, 1),
          Literal.new(2)
        )
      ),
      Token.new(TokenTypes::STAR, "*", nil, 1),
      Grouping.new(
        Binary.new(
          Literal.new(4),
          Token.new(TokenTypes::MINUS, "-", nil, 1),
          Literal.new(3)
        )
      ),
    )
  end
end
