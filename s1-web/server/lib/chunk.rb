module Opcodes
  LOAD_CONSTANT = "LOAD-CONSTANT"
  RETURN = "RETURN"

  ADD = "ADD"
  SUBTRACT = "SUBTRACT"
  MULTIPLY = "MULTIPLY"
  DIVIDE = "DIVIDE"

  POP = "POP"
  NIL = "NIL"

  PRINT = "PRINT"

  DEFINE_GLOBAL= "DEFINE-GLOBAL"
  GET_GLOBAL= "GET-GLOBAL"
  SET_GLOBAL= "SET-GLOBAL"

  GET_LOCAL= "GET-LOCAL"
  SET_LOCAL = "SET-LOCAL"
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
