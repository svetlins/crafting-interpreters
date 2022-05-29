require "ostruct"

module ALox
  class VM
    class Function
      def self.top_level_script
        OpenStruct.new(
          function_name: "__toplevel__",
          upvalues: []
        )
      end

      attr_reader :upvalues

      def initialize(compiled_function, upvalues)
        @compiled_function = compiled_function
        @upvalues = upvalues
      end

      def function_name
        @compiled_function.name
      end

      def arity
        @compiled_function.arity
      end
    end

    class CallFrame
      attr_reader :function, :stack_top

      def initialize(executable, stack, function, stack_top = 0)
        @executable = executable
        @stack = stack
        @function = function
        @ip = 0
        @stack_top = stack_top
      end

      def read_code
        @ip += 1
        @executable.functions[@function.function_name][@ip - 1]
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

      def set_value(new_value)
        if defined? @value
          @value = new_value
        else
          @stack[pointer] = new_value
        end
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
        CallFrame.new(executable, @stack, Function.top_level_script)
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
          compiled_function = call_frame.read_constant(call_frame.read_code)

          upvalues =
            compiled_function.upvalue_count.times.map do |upvalue_description|
              is_local, slot = call_frame.read_code, call_frame.read_code

              if is_local == 1
                new_upvalue =
                  open_upvalues.detect { _1.pointer == call_frame.stack_top + slot } ||
                    Upvalue.new(call_frame.stack_top + slot, @stack)

                open_upvalues << new_upvalue
                open_upvalues.sort_by! { -(_1.pointer) }

                new_upvalue
              else
                call_frame.function.upvalues[slot]
              end
            end

          @stack.push(
            Function.new(compiled_function, upvalues)
          )
        when Opcodes::SET_GLOBAL
          @globals[call_frame.read_constant(call_frame.read_code)] = @stack.last
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
          @stack.push(call_frame.function.upvalues[call_frame.read_code].value)
        when Opcodes::SET_UPVALUE
          call_frame.function.upvalues[call_frame.read_code].set_value(@stack.last)
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
          fail 'corrupted stack' if @stack.empty?
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
          function = @stack[-argument_count - 1]

          if function.is_a? Function
            if function.arity == argument_count
              call_frames << CallFrame.new(
                executable,
                @stack,
                function,
                @stack.size - argument_count
              )
            else
              error("function #{function.function_name} takes #{function.arity} arguments but #{argument_count} provided")
            end
          else
            error("#{lox_object_to_string(function)} is not function")
          end
        when Opcodes::RETURN
          result = @stack.pop

          while open_upvalues.count > 0 && open_upvalues.first.pointer >= call_frame.stack_top
            upvalue = open_upvalues.shift
            upvalue.close!
          end

          call_frames.pop

          @stack[0..-1] = @stack[0..call_frame.stack_top - 2]

          @stack.push(result)
        when Opcodes::CLOSE_UPVALUE
          fail 'corrupted upvalues' if open_upvalues.empty?
          open_upvalues.shift.close!

          fail 'corrupted stack' if @stack.empty?
          @stack.pop
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

        print_debug_info(op) if debug
      end

      @stack.pop

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
      if lox_object.is_a? Function
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

    def print_debug_info(op)
      puts "DEBUG: #{op}"
      print_stack
      puts
    end

    def print_stack
      puts [
        "STACK:",
        "[",
        *@stack.map { |value| value.is_a?(Function) ? "<#{value.function_name}>" : value.inspect }.join(", "),
        "]"
      ].join(" ")
    end
  end
end
