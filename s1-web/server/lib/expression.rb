require 'scanner'

module Expression
  @expression_kinds = []

  def self.define_expression_type(name, *fields, has_static_resolution: false)
    @expression_kinds << name

    Struct.new(*fields) do
      def expression?; true; end
      def statement?; false; end

      if has_static_resolution
        attr_accessor :depth, :location
      end

      define_method :accept do |visitor|
        visitor.public_send(:"visit_#{name}", self)
      end
    end
  end

  def self.generate_visitors
    @expression_kinds.map do |name|
      "def visit_#{name}; end"
    end.join("\n\n")
  end

  Assign = define_expression_type('assign', :name, :value, has_static_resolution: true)
  Variable = define_expression_type('variable', :name, has_static_resolution: true)
  SuperExpression = define_expression_type('super_expression', :keyword, :method_name, has_static_resolution: true)
  ThisExpression = define_expression_type('this_expression', :keyword, has_static_resolution: true)

  Binary = define_expression_type('binary', :left, :operator, :right)
  Grouping = define_expression_type('grouping', :expression)
  Literal = define_expression_type('literal', :value)
  Logical = define_expression_type('logical', :left, :operator, :right)
  Unary = define_expression_type('unary', :operator, :right)
  Call = define_expression_type('call', :callee, :paren, :arguments)
  GetExpression = define_expression_type('get_expression', :object, :name)
  SetExpression = define_expression_type('set_expression', :object, :name, :value)
end
