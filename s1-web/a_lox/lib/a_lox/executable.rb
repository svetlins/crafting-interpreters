module ALox
  class Executable
    PLACEHOLDER = "PLACEHOLDER"

    attr_reader :functions, :constants

    def initialize
      @functions = {}
      @constants = []
    end

    def reset_function(function)
      @functions[function] = []
    end

    def write(function, opcode)
      @functions[function] << opcode
      @functions[function].size
    end

    def patch_jump(function, jump_offset)
      jump = @functions[function].size - jump_offset - 2

      first_byte, second_byte = [jump].pack("s").bytes

      @functions[function][jump_offset] = first_byte
      @functions[function][jump_offset + 1] = second_byte
    end

    def add_constant(constant)
      if @constants.include?(constant)
        @constants.index(constant)
      else
        @constants << constant
        @constants.size - 1
      end
    end

    def size(function)
      @functions[function].size
    end

    def as_json
      {
        functions: @functions,
        constants: @constants.map { |constant| constant.respond_to?(:as_json) ? constant.as_json : constant }
      }
    end
  end
end
