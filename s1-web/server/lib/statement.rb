require 'scanner'

module Statement
  @names = []

  def self.define_statement_type(name, *fields, additional: [])
    @names << name

    Struct.new(*fields) do
      def expression?; true; end
      def statement?; false; end

      if additional.any?
        attr_accessor *additional
      end

      define_method :accept do |visitor|
        visitor.public_send(:"visit_#{name}", self)
      end
    end
  end

  def self.generate_visitors
    @names.map do |name|
      "def visit_#{name}; end"
    end.join("\n")
  end

  ExpressionStatement = define_statement_type('expression_statement', :expression)
  FunctionStatement = define_statement_type('function_statement', :name, :parameters, :body, additional: %i[allocation full_name parameter_allocations upvalues])
  ReturnStatement = define_statement_type('return_statement', :keyword, :value)
  PrintStatement = define_statement_type('print_statement', :expression)
  VarStatement = define_statement_type('var_statement', :name, :initializer, additional: %i[allocation])
  BlockStatement = define_statement_type('block_statement', :statements, additional: %i[locals])
  IfStatement = define_statement_type('if_statement', :condition, :then_branch, :else_branch)
  WhileStatement = define_statement_type('while_statement', :condition, :body)
  ClassStatement = define_statement_type('class_statement', :name, :superclass, :methods)
end
