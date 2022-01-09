require 'executable'
require 'opcodes'
require 'ostruct'

module VM
  extend self

  class HeapValue
    attr_accessor :value
  end

  class Callable
    def self.top_level_script
      OpenStruct.new(
        function_name: '__script__',
        heap_slots: [],
        heap_view: {}
      )
    end

    def initialize(function_descriptor, heap_view)
      @function_descriptor = function_descriptor
      @heap_view = heap_view
    end

    def function_name
      @function_descriptor.name
    end

    def heap_slots
      @function_descriptor.heap_slots
    end

    def heap_view
      @heap_view
    end
  end

  class StackFrame
    attr_reader :closure, :heap_slots, :stack_top

    def initialize(executable, stack, closure, heap_slots, stack_top)
      @executable = executable
      @stack = stack
      @closure = closure
      @heap_slots = heap_slots
      @ip = 0
      @stack_top = stack_top
    end

    def function_name
      @closure.function_name
    end

    def read_executable
      @ip += 1

      @executable.functions[function_name][:code][@ip - 1]
    end

    def read_constant(constant_index)
      @executable.functions[function_name][:constants][constant_index]
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

  def execute(executable, out: $stdout)
    stack = []
    globals = {}

    stack_frames = [
      StackFrame.new(executable, stack, Callable.top_level_script, [], 0)
    ]

    loop do
      stack_frame = stack_frames.last

      break if stack_frame.nil?

      op = stack_frame.read_executable

      case op
      when Opcodes::LOAD_CONSTANT
        stack.push(stack_frame.read_constant(stack_frame.read_executable))
      when Opcodes::LOAD_CLOSURE
        function = stack_frame.read_constant(stack_frame.read_executable)
        stack.push(Callable.new(function, function.heap_usages.map { [_1, stack_frame.closure.heap_view[_1] || stack_frame.heap_slots.fetch(_1)] }.to_h))
      when Opcodes::SET_GLOBAL
        stack.push(globals[stack_frame.read_constant(stack_frame.read_executable)] = stack.pop)
      when Opcodes::DEFINE_GLOBAL
        globals[stack_frame.read_constant(stack_frame.read_executable)] = stack.pop
      when Opcodes::GET_GLOBAL
        stack.push(globals[stack_frame.read_constant(stack_frame.read_executable)])
      when Opcodes::SET_LOCAL
        stack_frame.set_slot(stack_frame.read_executable, stack.last)
      when Opcodes::GET_LOCAL
        stack.push(stack_frame.slot(stack_frame.read_executable))
      when Opcodes::SET_HEAP
        heap_slot = stack_frame.read_executable
        heap_value = stack_frame.closure.heap_view[heap_slot] || stack_frame.heap_slots.fetch(heap_slot)
        heap_value.value = stack.last
      when Opcodes::INIT_HEAP
        heap_slot = stack_frame.read_executable
        stack_frame.heap_slots.fetch(heap_slot).value = stack.pop
      when Opcodes::GET_HEAP
        stack.push(
          stack_frame.closure.heap_view[stack_frame.read_executable].value
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
        argument_count = stack_frame.read_executable
        closure = stack[-argument_count - 1]
        heap_slots =
          closure.heap_slots.map { [_1, HeapValue.new] }.to_h

        stack_frames << StackFrame.new(
          executable,
          stack,
          closure,
          heap_slots,
          stack.size - argument_count
        )
      when Opcodes::RETURN
        result = stack.pop
        stack_frames.pop

        stack = stack[0...stack_frame.stack_top]

        stack.push(result)
      when Opcodes::PRINT
        out.puts(stack.pop.inspect)
      when Opcodes::JUMP_ON_FALSE
        jump_offset_byte1, jump_offset_byte2 = stack_frame.read_executable, stack_frame.read_executable
        stack_frame.jump(jump_offset_byte1, jump_offset_byte2) if falsey?(stack.last)
      when Opcodes::JUMP
        stack_frame.jump(stack_frame.read_executable, stack_frame.read_executable)
      else
        fail op.inspect
      end

      debug(binding) if ENV["VM_DEBUG"]
    end
  end

  def falsey?(value)
    !value
  end

  def equal?(a, b)
    a == b # TODO
  end

  def debug(b)
    puts b.local_variable_get(:op)
    print_stack b.local_variable_get(:stack)
    puts
  end

  def print_stack(stack)
    puts [
      '[',
      *stack.map { |value| value.is_a?(Callable) ? "<#{value.function_name}>" : value},
      ']',
    ].join(" ")
  end
end
