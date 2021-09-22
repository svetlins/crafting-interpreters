require 'lox_instance'

class LoxClass
  def initialize(name, methods)
    @name = name
    @methods = methods
  end

  def lox_call(interpreter, arguments)
    LoxInstance.new(self)
  end

  def arity = 0

  def find_method(name)
    @methods[name]
  end

  def to_s
    @name
  end
end
