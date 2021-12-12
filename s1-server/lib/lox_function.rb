require 'environment'

class LoxFunction
  def initialize(declaration, closure, is_initializer)
    @declaration = declaration
    @closure = closure
    @is_initializer = is_initializer
  end

  def arity
    @declaration.parameters.count
  end

  def lox_call(interpreter, arguments)
    environment = Environment.new(@closure)

    @declaration.parameters.each_with_index do |parameter, index|
      environment.define(parameter.lexeme, arguments[index])
    end

    returned =
      catch :lox_return do
        interpreter.execute_block(@declaration.body, environment)
        nil
      end

    return @closure.unsafe_get!('this') if @is_initializer
    return returned
  end

  def bind(instance)
    instance_scope = Environment.new(@closure)
    instance_scope.define('this', instance)
    LoxFunction.new(@declaration, instance_scope, @is_initializer)
  end

  def to_s
    "<fn #{@declaration.name.lexeme}>"
  end
end
