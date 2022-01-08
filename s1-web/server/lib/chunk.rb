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

  def touch(function)
    init_function(function)
  end

  def write(function, opcode)
    init_function(function)
    @functions[function][:code] << opcode
    @functions[function][:code].size
  end

  def patch_jump(function, jump_offset)
    jump = @functions[function][:code].size - jump_offset - 2

    first_byte, second_byte = [jump].pack('s').bytes

    @functions[function][:code][jump_offset] = first_byte
    @functions[function][:code][jump_offset + 1] = second_byte
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
