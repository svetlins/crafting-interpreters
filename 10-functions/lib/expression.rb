require 'scanner'

module Expression
  def self.define_expression_type(name, *fields)
    Struct.new(*fields) do
      define_method :accept do |visitor|
        visitor.public_send(:"visit_#{name}", self)
      end
    end
  end

  Assign = define_expression_type('assign', :name, :value)
  Binary = define_expression_type('binary', :left, :operator, :right)
  Grouping = define_expression_type('grouping', :expression)
  Literal = define_expression_type('literal', :value)
  Logical = define_expression_type('logical', :left, :operator, :right)
  Unary = define_expression_type('unary', :operator, :right)
  Variable = define_expression_type('variable', :name)
end
