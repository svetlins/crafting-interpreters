require 'scanner'

module Statement
  def self.define_statement_type(name, *fields)
    Struct.new(*fields) do
      define_method :accept do |visitor|
        visitor.public_send(:"visit_#{name}", self)
      end
    end
  end

  ExpressionStatement = define_statement_type('expression_statement', :expression)
  PrintStatement = define_statement_type('print_statement', :expression)
  VarStatement = define_statement_type('var_statement', :name, :initializer)
  BlockStatement = define_statement_type('block', :statements)
end
