require 'chunk'
require 'opcodes'

module VM
  extend self

  class HeapValue
    attr_accessor :value
  end

  Closure = Struct.new(:function, :heap_view)

  class StackFrame
    attr_reader :closure, :heap_slots

    def initialize(chunk, stack, closure, heap_slots, stack_top)
      @chunk = chunk
      @stack = stack
      @closure = closure
      @heap_slots = heap_slots
      @ip = 0
      @stack_top = stack_top
    end

    def function_name
      @closure.function.name
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

    def set_slot(offset, value)
      @stack[@stack_top + offset] = value
    end

    def jump(offset_byte_1, ofsset_byte_2)
      @ip += [offset_byte_1, ofsset_byte_2].map(&:chr).join.unpack('s').first
    end
  end

  def execute(chunk, out: $stdout)
    stack = []
    globals = {}

    stack_frames = [
      StackFrame.new(chunk, stack, Closure.new(Function.new(0, '__script__', nil), {}), [], 0)
    ]

    loop do
      stack_frame = stack_frames.last

      break if stack_frame.nil?

      op = stack_frame.read_chunk

      # puts op
      # pp stack
      # p stack_frame
      # puts

      case op
      when Opcodes::LOAD_CONSTANT
        stack.push(stack_frame.read_constant(stack_frame.read_chunk))
      when Opcodes::LOAD_CLOSURE
        function = stack_frame.read_constant(stack_frame.read_chunk)
        stack.push(Closure.new(function, function.heap_usages.map { [_1, stack_frame.closure.heap_view[_1] || stack_frame.heap_slots.fetch(_1)] }.to_h))
      when Opcodes::SET_GLOBAL
        stack.push(globals[stack_frame.read_constant(stack_frame.read_chunk)] = stack.pop)
      when Opcodes::DEFINE_GLOBAL
        globals[stack_frame.read_constant(stack_frame.read_chunk)] = stack.pop
      when Opcodes::GET_GLOBAL
        stack.push(globals[stack_frame.read_constant(stack_frame.read_chunk)])
      when Opcodes::SET_LOCAL
        stack_frame.set_slot(stack_frame.read_chunk, stack.last)
      when Opcodes::GET_LOCAL
        stack.push(stack_frame.slot(stack_frame.read_chunk))
      when Opcodes::SET_HEAP
        heap_slot = stack_frame.read_chunk
        heap_value = stack_frame.closure.heap_view[heap_slot] || stack_frame.heap_slots.fetch(heap_slot)
        heap_value.value = stack.last
      when Opcodes::INIT_HEAP
        heap_slot = stack_frame.read_chunk
        stack_frame.heap_slots.fetch(heap_slot).value = stack.pop
      when Opcodes::GET_HEAP
        stack.push(
          stack_frame.closure.heap_view[stack_frame.read_chunk].value
        )
      when Opcodes::NIL
        stack.push(nil)
      when Opcodes::NOT
        stack.push(falsey?(stack.pop))
      when Opcodes::NEGATE
        stack.push(-stack.pop)
      when Opcodes::POP
        stack.pop
      when Opcodes::ADD
        stack.push(stack.pop + stack.pop)
      when Opcodes::DIVIDE
        b, a = stack.pop, stack.pop
        stack.push(a / b)
      when Opcodes::MULTIPLY
        stack.push(stack.pop * stack.pop)
      when Opcodes::EQUAL
        stack.push(equal?(stack.pop, stack.pop))
      when Opcodes::GREATER
        stack.push(stack.pop < stack.pop)
      when Opcodes::LESSER
        stack.push(stack.pop > stack.pop)
      when Opcodes::CALL
        argument_count = stack_frame.read_chunk
        closure = stack[-argument_count - 1]
        heap_slots =
          closure.function.heap_slots.map { [_1, HeapValue.new] }.to_h

        stack_frames << StackFrame.new(
          chunk,
          stack,
          closure,
          heap_slots,
          stack.size - argument_count
        )
      when Opcodes::RETURN
        stack_frames.pop
      when Opcodes::PRINT
        out.puts(stack.pop.inspect)
      when Opcodes::JUMP_ON_FALSE
        jump_offset_byte1, jump_offset_byte2 = stack_frame.read_chunk, stack_frame.read_chunk
        stack_frame.jump(jump_offset_byte1, jump_offset_byte2) if falsey?(stack.last)
      when Opcodes::JUMP
        stack_frame.jump(stack_frame.read_chunk, stack_frame.read_chunk)
      else
        fail op.inspect
      end
    end
  end

  def falsey?(value)
    !value
  end

  def equal?(a, b)
    a == b # TODO
  end
end
