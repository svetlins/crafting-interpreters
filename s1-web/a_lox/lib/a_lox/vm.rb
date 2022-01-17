require "ostruct"

module ALox
  class VM
    class HeapValue
      attr_accessor :value
    end

    class Callable
      def self.top_level_script
        OpenStruct.new(
          function_name: "__script__",
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

      attr_reader :heap_view
    end

    class CallFrame
      attr_reader :callable, :heap_slots, :stack_top

      def initialize(executable, stack, callable, heap_slots = [], stack_top = 0)
        @executable = executable
        @stack = stack
        @callable = callable
        @heap_slots = heap_slots
        @ip = 0
        @stack_top = stack_top
      end

      def read_code
        @ip += 1
        @executable.functions[@callable.function_name][@ip - 1]
      end

      def read_constant(constant_index)
        @executable.constants[constant_index]
      end

      def get_stack_slot(offset)
        @stack[@stack_top + offset]
      end

      def set_stack_slot(offset, value)
        @stack[@stack_top + offset] = value
      end

      def jump(offset_byte_1, ofsset_byte_2)
        @ip += [offset_byte_1, ofsset_byte_2].map(&:chr).join.unpack1("s")
      end
    end

    def self.execute(executable, out: $stdout, debug: false)
      new.execute(executable, out: out, debug: debug)
    end

    def initialize(error_reporter: nil)
      @stack = []
      @globals = {}
      @error_reporter = error_reporter
    end

    def execute(executable, out: $stdout, debug: false)
      call_frames = [
        CallFrame.new(executable, @stack, Callable.top_level_script)
      ]

      loop do
        call_frame = call_frames.last

        break if call_frame.nil?

        op = call_frame.read_code

        case op
        when Opcodes::LOAD_CONSTANT
          @stack.push(call_frame.read_constant(call_frame.read_code))
        when Opcodes::LOAD_CLOSURE
          function_descriptor = call_frame.read_constant(call_frame.read_code)

          heap_view =
            function_descriptor.heap_usages.map do |heap_usage|
              [
                heap_usage,
                call_frame.callable.heap_view[heap_usage] || call_frame.heap_slots.fetch(heap_usage)
              ]
            end.to_h

          @stack.push(
            Callable.new(function_descriptor, heap_view)
          )
        when Opcodes::SET_GLOBAL
          @stack.push(@globals[call_frame.read_constant(call_frame.read_code)] = @stack.pop)
        when Opcodes::DEFINE_GLOBAL
          @globals[call_frame.read_constant(call_frame.read_code)] = @stack.pop
        when Opcodes::GET_GLOBAL
          @stack.push(@globals[call_frame.read_constant(call_frame.read_code)])
        when Opcodes::SET_LOCAL
          call_frame.set_stack_slot(call_frame.read_code, @stack.last)
        when Opcodes::GET_LOCAL
          @stack.push(call_frame.get_stack_slot(call_frame.read_code))
        when Opcodes::SET_HEAP
          heap_slot = call_frame.read_code
          heap_value = call_frame.callable.heap_view[heap_slot] || call_frame.heap_slots.fetch(heap_slot)
          heap_value.value = @stack.last
        when Opcodes::INIT_HEAP
          heap_slot = call_frame.read_code
          call_frame.heap_slots.fetch(heap_slot).value = @stack.pop
        when Opcodes::GET_HEAP
          @stack.push(
            call_frame.callable.heap_view[call_frame.read_code].value
          )
        when Opcodes::NIL
          @stack.push(nil)
        when Opcodes::NOT
          @stack.push(falsey?(@stack.pop))
        when Opcodes::NEGATE
          @stack.push(-@stack.pop)
        when Opcodes::POP
          @stack.pop
        when Opcodes::ADD
          b, a = @stack.pop, @stack.pop
          @stack.push(a + b)
        when Opcodes::SUBTRACT
          b, a = @stack.pop, @stack.pop
          @stack.push(a - b)
        when Opcodes::DIVIDE
          b, a = @stack.pop, @stack.pop
          @stack.push(a / b)
        when Opcodes::MULTIPLY
          b, a = @stack.pop, @stack.pop
          @stack.push(a * b)
        when Opcodes::EQUAL
          @stack.push(equal?(@stack.pop, @stack.pop))
        when Opcodes::GREATER
          b, a = @stack.pop, @stack.pop
          @stack.push(a > b)
        when Opcodes::LESSER
          b, a = @stack.pop, @stack.pop
          @stack.push(a < b)
        when Opcodes::CALL
          argument_count = call_frame.read_code
          callable = @stack[-argument_count - 1]
          heap_slots =
            callable.heap_slots.map { |slot| [slot, HeapValue.new] }.to_h

          call_frames << CallFrame.new(
            executable,
            @stack,
            callable,
            heap_slots,
            @stack.size - argument_count
          )
        when Opcodes::RETURN
          result = @stack.pop
          call_frames.pop

          @stack[0..-1] = @stack[0...call_frame.stack_top - 1]

          @stack.push(result)
        when Opcodes::PRINT
          out.puts(@stack.pop.inspect)
        when Opcodes::JUMP_ON_FALSE
          jump_offset_byte1, jump_offset_byte2 = call_frame.read_code, call_frame.read_code
          call_frame.jump(jump_offset_byte1, jump_offset_byte2) if falsey?(@stack.last)
        when Opcodes::JUMP
          call_frame.jump(call_frame.read_code, call_frame.read_code)
        else
          fail op.inspect
        end

        print_debug_info(binding) if debug
      end
    rescue => e
      error(e.message, call_frames)
    end

    def falsey?(value)
      !value
    end

    def equal?(a, b)
      a == b # TODO
    end

    def error(message, call_frames)
      @error_reporter&.report_runtime_error(message)
    end

    def print_debug_info(b)
      puts b.local_variable_get(:op)
      print_stack
      puts
    end

    def print_stack
      puts [
        "[",
        *@stack.map { |value| value.is_a?(Callable) ? "<#{value.function_name}>" : value },
        "]"
      ].join(" ")
    end
  end
end
