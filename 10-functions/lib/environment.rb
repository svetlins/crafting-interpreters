require 'interpreter'

class Environment
  def initialize(enclosing = nil)
    @binding = {}
    @enclosing = enclosing
  end

  def define(name, value)
    @binding[name] = value
  end

  def assign(name, value)
    if @binding.include?(name.lexeme)
      @binding[name.lexeme] = value
    elsif @enclosing
      @enclosing.assign(name, value)
    else
      raise Interpreter::LoxRuntimeError.new(name, "Undefined variable #{name.lexeme}")
    end
  end

  def get(name)
    value = @binding[name.lexeme]
    value ||= @enclosing&.get(name)

    value or raise Interpreter::LoxRuntimeError.new(name, "Undefined name #{name.lexeme}.")
  end
end
