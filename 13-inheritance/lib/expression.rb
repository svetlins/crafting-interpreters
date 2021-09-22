require 'scanner'

module Expression
  def self.define_expression_type(name, *fields)
    Struct.new(*fields) do
      def expression? = true
      def statement? = false

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
  Call = define_expression_type('call', :callee, :paren, :arguments)
  GetExpression = define_expression_type('get_expression', :object, :name)
  SetExpression = define_expression_type('set_expression', :object, :name, :value)
  SuperExpression = define_expression_type('super_expression', :keyword, :method_name)
  ThisExpression = define_expression_type('this_expression', :keyword)
end
