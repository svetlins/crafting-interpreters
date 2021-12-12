class LoxInstance
  def initialize(klass)
    @klass = klass
    @fields = {}
  end

  def get(name)
    if @fields.has_key?(name.lexeme)
      @fields[name.lexeme]
    elsif method = @klass.find_method(name.lexeme)
      method.bind(self)
    else
      raise Interpreter::LoxRuntimeError.new(name, "Missing property #{name.lexeme} for #{self}")
    end
  end

  def set(name, value)
    @fields[name.lexeme] = value
  end

  def to_s
    "#{@klass} instance"
  end
end
