require 'chunk'

module VM
  extend self

  class StackFrame
    attr_reader :function_name

    def initialize(chunk, stack, function_name, stack_top = 0)
      @chunk = chunk
      @stack = stack
      @function_name = function_name
      @ip = 0
      @stack_top = stack_top
    end

    def read_chunk
      @ip += 1

      @chunk.functions[function_name][:code][@ip - 1]
    end

    def read_constant(constant_index)
      @chunk.functions[function_name][:constants][constant_index]
    end

    def slot(offset)
      @stack[@stack_top + offset]
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

      break if stack_frame.nil?

      case op = stack_frame.read_chunk
      when Opcodes::LOAD_CONSTANT
        stack.push(stack_frame.read_constant(stack_frame.read_chunk))
      when Opcodes::DEFINE_GLOBAL
        globals[stack_frame.read_constant(stack_frame.read_chunk)] = stack.pop
      when Opcodes::GET_GLOBAL
        stack.push(globals[stack_frame.read_constant(stack_frame.read_chunk)])
      when Opcodes::GET_LOCAL
        stack.push(stack_frame.slot(stack_frame.read_chunk))
      when Opcodes::NIL
        stack.push(nil)
      when Opcodes::POP
        stack.pop
      when Opcodes::ADD
        stack.push(stack.pop + stack.pop)
      when Opcodes::DIVIDE
        b, a = stack.pop, stack.pop
        stack.push(a / b)
      when Opcodes::MULTIPLY
        stack.push(stack.pop * stack.pop)
      when Opcodes::CALL
        argument_count = stack_frame.read_chunk
        function = stack[-argument_count - 1]
        stack_frames << StackFrame.new(chunk, stack, function.name, stack.size - argument_count)
      when Opcodes::RETURN
        stack_frames.pop
      when Opcodes::PRINT
        puts stack.pop
      else
        fail op.inspect
      end
    end
  end
end
