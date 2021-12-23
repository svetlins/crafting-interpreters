module Opcodes
  LOAD_CONSTANT = "LOAD-CONSTANT"
  RETURN = "RETURN"

  ADD = "ADD"
  SUBTRACT = "SUBTRACT"
  MULTIPLY = "MULTIPLY"
  DIVIDE = "DIVIDE"

  POP = "POP"

  PRINT = "PRINT"
end

class Chunk
  def initialize
    @code = []
    @constants = []
  end

  def write(opcode)
    @code << opcode
  end

  def add_constant(constant)
    @constants << constant

    @constants.size - 1
  end

  def disassemble
    @code
  end

  def as_json
    {code: @code, constants: @constants}
  end
end
