require 'chunk'

module VM
  extend self

  class StackFrame
    attr_reader :function_name

    def initialize(chunk, stack, function_name)
      @chunk = chunk
      @function_name = function_name
      @ip = 0
      @slots = stack.size
    end

    def read_chunk
      @ip += 1

      @chunk.functions[function_name][:code][@ip - 1]
    end

    def read_constant(constant_index)
      @chunk.functions[function_name][:constants][constant_index]
    end

    def slot(offset)
      @stack[offset]
    end
  end

  def execute(chunk)
    stack = []
    globals = {}

    stack_frames = [
      StackFrame.new(chunk, stack, '__script__')
    ]

    loop do
      stack_frame = stack_frames.last

      case stack_frame.read_chunk
      when Opcodes::LOAD_CONSTANT
        stack.push(stack_frame.read_constant(stack_frame.read_chunk))
      when Opcodes::DEFINE_GLOBAL
        globals[stack_frame.read_constant(stack_frame.read_chunk)] = stack.pop
      when Opcodes::GET_GLOBAL
        stack.push(globals[stack_frame.read_constant(stack_frame.read_chunk)])
      when Opcodes::NIL
        stack.push(nil)
      when Opcodes::ADD
        stack.push(stack.pop + stack.pop)
      when Opcodes::RETURN
        break
      when Opcodes::PRINT
        puts stack.pop
      else
        fail
      end
    end
  end
end
