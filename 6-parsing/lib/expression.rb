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
end
