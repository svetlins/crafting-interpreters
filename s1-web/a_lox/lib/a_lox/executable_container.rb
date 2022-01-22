module ALox
  class ExecutableContainer
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

      first_byte, second_byte = BinaryUtils.pack_short(jump)

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

    def serialize
      {
        functions: @functions,
        constants: @constants.map { |constant| constant.respond_to?(:serialize) ? constant.serialize : constant }
      }
    end
  end
end
