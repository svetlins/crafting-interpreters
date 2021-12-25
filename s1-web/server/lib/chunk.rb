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

  JUMP_ON_FALSE = "JUMP-ON-FALSE"
  JUMP = "JUMP"
end

class Chunk
  PLACEHOLDER = "PLACEHOLDER"

  def initialize
    @code = []
    @constants = []
  end

  def write(opcode)
    @code << opcode

    @code.size
  end

  def patch_jump(jump_offset)
    jump = @code.size - jump_offset - 2

    @code[jump_offset] = jump >> 8 & 0xff
    @code[jump_offset + 1] = jump & 0xff
  end

  def add_constant(constant)
    @constants << constant

    @constants.size - 1
  end

  def size
    @code.size
  end

  def as_json
    {code: @code, constants: @constants}
  end
end
