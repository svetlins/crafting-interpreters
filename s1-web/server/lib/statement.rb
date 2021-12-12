require 'scanner'

module Statement
  @names = []

  def self.define_statement_type(name, *fields)
    @names << name

    Struct.new(*fields) do
      def expression? = false
      def statement? = true

      define_method :accept do |visitor|
        visitor.public_send(:"visit_#{name}", self)
      end

      define_method :as_json do
        hash =
          fields.map do |field|
            field_value = self.public_send(field)
            if field_value.respond_to?(:as_json)
              field_value = field_value.as_json
            elsif field_value.is_a? Array
              field_value = {children: field_value.map(&:as_json)}
            else
              field_value = field_value.inspect
            end

            field_value
          end

        {name: name, children: hash}
      end
    end
  end

  def self.generate_visitors
    @names.map do |name|
      "def visit_#{name}; end"
    end.join("\n\n")
  end

  ExpressionStatement = define_statement_type('expression_statement', :expression)
  FunctionStatement = define_statement_type('function_statement', :name, :parameters, :body)
  ReturnStatement = define_statement_type('return_statement', :keyword, :value)
  PrintStatement = define_statement_type('print_statement', :expression)
  VarStatement = define_statement_type('var_statement', :name, :initializer)
  BlockStatement = define_statement_type('block_statement', :statements)
  IfStatement = define_statement_type('if_statement', :condition, :then_branch, :else_branch)
  WhileStatement = define_statement_type('while_statement', :condition, :body)
  ClassStatement = define_statement_type('class_statement', :name, :superclass, :methods)
end
