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
    else
      raise Interpreter::LoxRuntimeError.new(name, "Undefined variable #{name.lexeme}")
    end
  end

  def get(name)
    if @binding.has_key? name.lexeme
      @binding[name.lexeme]
    else
      raise Interpreter::LoxRuntimeError.new(name, "Undefined name #{name.lexeme}.")
    end
  end

  def get_at(depth, name)
    ancestor(depth).get(name)
  end

  def unsafe_get!(name)
    @binding.fetch(name)
  end

  def assign_at(depth, name, value)
    ancestor(depth).assign(name, value)
  end

  def ancestor(depth)
    depth == 0 ? self : @enclosing.ancestor(depth - 1)
  end
end
