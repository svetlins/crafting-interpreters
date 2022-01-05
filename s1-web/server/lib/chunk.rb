module Opcodes
  LOAD_CONSTANT = "LOAD-CONSTANT"
  LOAD_CLOSURE = "LOAD-CLOSURE"
  RETURN = "RETURN"

  ADD = "ADD"
  SUBTRACT = "SUBTRACT"
  MULTIPLY = "MULTIPLY"
  DIVIDE = "DIVIDE"

  POP = "POP"
  NIL = "NIL"

  PRINT = "PRINT"

  DEFINE_GLOBAL = "DEFINE-GLOBAL"
  GET_GLOBAL = "GET-GLOBAL"
  SET_GLOBAL = "SET-GLOBAL"

  GET_LOCAL = "GET-LOCAL"
  SET_LOCAL = "SET-LOCAL"

  SET_HEAP = "SET-HEAP"
  INIT_HEAP = "INIT-HEAP"
  GET_HEAP = "GET-HEAP"

  JUMP_ON_FALSE = "JUMP-ON-FALSE"
  JUMP = "JUMP"

  CALL = "CALL"
end

class Chunk
  PLACEHOLDER = "PLACEHOLDER"

  attr_reader :functions

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
    @functions.transform_values do |function|
      {
        code: function[:code],
        constants: function[:constants].map { |constant| constant.respond_to?(:as_json) ? constant.as_json : constant }
      }
    end
  end
end
