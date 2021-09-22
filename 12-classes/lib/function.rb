require 'environment'

class LoxFunction
  def initialize(declaration, closure)
    @declaration = declaration
    @closure = closure
  end

  def arity
    @declaration.parameters.count
  end

  def lox_call(interpreter, arguments)
    environment = Environment.new(@closure)

    @declaration.parameters.each_with_index do |parameter, index|
      environment.define(parameter.lexeme, arguments[index])
    end

    catch :lox_return do
      interpreter.execute_block(@declaration.body, environment)

      nil
    end
  end

  def bind(instance)
    instance_scope = Environment.new(@closure)
    instance_scope.define('this', instance)
    LoxFunction.new(@declaration, instance_scope)
  end

  def to_s
    "<fn #{@declaration.name.lexeme}>"
  end
end
