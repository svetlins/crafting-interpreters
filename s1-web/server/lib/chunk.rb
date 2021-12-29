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

  CALL = "CALL"
end

class Chunk
  PLACEHOLDER = "PLACEHOLDER"

  def initialize
    @functions = {}
  end

  def init_function(function)
    @functions[function] ||= {
      code: [],
      constants: [],
    }
  end

  def write(function, opcode)
    init_function(function)
    @functions[function][:code] << opcode
    @functions[function][:code].size
  end

  def patch_jump(function, jump_offset)
    jump = @code.size - jump_offset - 2

    @code[jump_offset] = jump >> 8 & 0xff
    @code[jump_offset + 1] = jump & 0xff
  end

  def add_constant(function, constant)
    init_function(function)
    @functions[function][:constants] << constant
    @functions[function][:constants].size - 1
  end

  def size(function)
    @functions[function][:code].size
  end

  def as_json
    @functions
  end
end
