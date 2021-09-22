require 'lox_instance'

class LoxClass
  def initialize(name, methods)
    @name = name
    @methods = methods
  end

  def lox_call(interpreter, arguments)
    instance = LoxInstance.new(self)

    if initializer = find_method('init')
      initializer.bind(instance).lox_call(interpreter, arguments)
    end

    instance
  end

  def arity
    if initializer = find_method('init')
      initializer.arity
    else
      0
    end
  end

  def find_method(name)
    @methods[name]
  end

  def to_s
    @name
  end
end
