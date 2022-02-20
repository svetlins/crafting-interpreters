require "ostruct"

module ALox
  class UpvalueVM
    class Callable
      def self.top_level_script
        OpenStruct.new(
          function_name: "__toplevel__",
          upvalues: []
        )
      end

      attr_reader :upvalues

      def initialize(function_descriptor, upvalues)
        @function_descriptor = function_descriptor
        @upvalues = upvalues
      end

      def function_name
        @function_descriptor.name
      end

      def arity
        @function_descriptor.arity
      end
    end

    class CallFrame
      attr_reader :callable, :stack_top

      def initialize(executable, stack, callable, stack_top = 0)
        @executable = executable
        @stack = stack
        @callable = callable
        @ip = 0
        @stack_top = stack_top
      end

      def read_code
        @ip += 1
        @executable.functions[@callable.function_name][@ip - 1]
      end

      def read_short
        BinaryUtils.unpack_short(read_code, read_code)
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

      def jump(location)
        @ip += location
      end
    end

    class Upvalue
      attr_reader :pointer

      def initialize(pointer, stack)
        @pointer = pointer
        @stack = stack
      end

      def close!
        @value = @stack[pointer]
      end

      def value
        @value || @stack[pointer]
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

      open_upvalues = []

      @had_error = false

      loop do
        call_frame = call_frames.last

        break if call_frame.nil?
        break if @had_error

        op = call_frame.read_code

        case op
        when Opcodes::LOAD_CONSTANT
          @stack.push(call_frame.read_constant(call_frame.read_code))
        when Opcodes::LOAD_CLOSURE
          function_descriptor = call_frame.read_constant(call_frame.read_code)

          upvalues =
            function_descriptor.upvalue_count.times.map do |upvalue_description|
              is_local, slot = call_frame.read_code, call_frame.read_code

              if is_local == 1
                new_upvalue = Upvalue.new(slot + 1, @stack)

                open_upvalues << new_upvalue
                open_upvalues.sort_by! { -(_1.pointer) }

                new_upvalue
              else
                call_frame.callable.upvalues[slot]
              end
            end

          @stack.push(
            Callable.new(function_descriptor, upvalues)
          )
        when Opcodes::SET_GLOBAL
          @stack.push(@globals[call_frame.read_constant(call_frame.read_code)] = @stack.pop)
        when Opcodes::DEFINE_GLOBAL
          @globals[call_frame.read_constant(call_frame.read_code)] = @stack.pop
        when Opcodes::GET_GLOBAL
          global_name = call_frame.read_constant(call_frame.read_code)
          error("Undefined global #{global_name}") unless @globals.has_key?(global_name)
          @stack.push(@globals[global_name])
        when Opcodes::SET_LOCAL
          call_frame.set_stack_slot(call_frame.read_code, @stack.last)
        when Opcodes::GET_LOCAL
          @stack.push(call_frame.get_stack_slot(call_frame.read_code))
        when Opcodes::GET_UPVALUE
          @stack.push(call_frame.callable.upvalues[call_frame.read_code].value)
        when Opcodes::NIL_OP
          @stack.push(nil)
        when Opcodes::TRUE_OP
          @stack.push(true)
        when Opcodes::FALSE_OP
          @stack.push(false)
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

          if callable.is_a? Callable
            call_frames << CallFrame.new(
              executable,
              @stack,
              callable,
              @stack.size - argument_count
            )
          else
            error("#{lox_object_to_string(callable)} is not callable")
          end
        when Opcodes::RETURN
          result = @stack.pop

          while open_upvalues.count > 0 && open_upvalues.first.pointer >= call_frame.stack_top
            upvalue = open_upvalues.shift
            upvalue.close!
          end

          call_frames.pop

          @stack[0..-1] = @stack[0...call_frame.stack_top - 1]

          @stack.push(result)
        when Opcodes::PRINT
          out.puts(lox_object_to_string(@stack.pop))
        when Opcodes::JUMP_ON_FALSE
          location = call_frame.read_short
          call_frame.jump(location) if falsey?(@stack.last)
        when Opcodes::JUMP
          call_frame.jump(call_frame.read_short)
        else
          fail op.inspect
        end

        print_debug_info(binding) if debug
      end

      fail 'corrupted open upvalues' if open_upvalues.any?
    end

    private

    def falsey?(value)
      !value
    end

    def equal?(a, b)
      a == b # TODO
    end

    def lox_object_to_string(lox_object)
      if lox_object.is_a? Callable
        "fun #{lox_object.function_name}/#{lox_object.arity}"
      elsif lox_object.nil?
        "nil"
      else
        lox_object.to_s
      end
    end

    def error(message)
      @had_error = true
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
