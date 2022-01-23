RSpec::Matchers.define :compile_to do |expected|
  def report_scanner_error(line, message)
    @compilation_error_type = :scanner
    @compilation_error = message
  end

  def report_parser_error(token, message)
    @compilation_error_type = :parser
    @compilation_error = message
  end

  def report_static_analysis_error(token, message)
    @compilation_error_type = :static_analysis
    @compilation_error = message
  end

  def report_compiler_error(message)
    @compilation_error_type = :compiler
    @compilation_error = message
  end

  def compile(source)
    tokens = ALox::Scanner.new(source, error_reporter: self).scan
    return if @compilation_error
    ast = ALox::Parser.new(tokens, error_reporter: self).parse
    return if @compilation_error
    executable = ALox::ExecutableContainer.new

    phase1 = ALox::StaticResolver::Phase1.new(error_reporter: self)
    phase2 = ALox::StaticResolver::Phase2.new(error_reporter: self)
    phase1.resolve(ast)
    phase2.resolve(ast)
    return if @compilation_error

    ALox::Compiler.new(ast, executable, error_reporter: self).compile
    return if @compilation_error

    executable
  end

  def process_args(args)
    if args.count == 1 && args.first =~ (/^(\+|-)/)
      ALox::BinaryUtils.pack_short(args.first.to_i).map(&:to_s)
    else
      args
    end
  end

  expected_executable =
    expected.lines
      .map(&:chomp)
      .map(&:strip)
      .chunk { _1.end_with?(":") }
      .map { _1.last }
      .each_slice(2)
      .map { [_1.first.first.chomp(":"), _1.last] }
      .to_h

  expectation_error = nil
  heap_allocations = {}

  match do |source|
    executable = compile(source)

    return false unless executable

    expected_executable.each do |function_name, ops|
      compiled_function = executable.functions[function_name].map(&:to_s)

      ops.each_with_index do |op, index|
        op, *args = op.split(/\s/)

        args = process_args(args)

        compiled_op = compiled_function.shift

        unless compiled_op == op
          expectation_error =
            "Wrong op in #{function_name}: expected #{op} at index #{index} but was #{compiled_op} instead"
          return false
        end

        args.each do |arg|
          compiled_arg = compiled_function.shift

          if arg.start_with?("H-")
            compiled_arg = [compiled_arg.to_i, compiled_function.shift.to_i].map(&:chr).join.unpack1("s>")

            variable = arg[/H-(\w+)/, 1]
            if heap_allocations[variable]
              if heap_allocations[variable] != compiled_arg
                expectation_error =
                  "Heap allocation in #{function_name} slot for #{op} " \
                  "was expected to be #{arg} but was " \
                  "#{heap_allocations.key(compiled_arg) ? "H-" + heap_allocations.key(compiled_arg) : compiled_arg}"
                return false
              end
            elsif heap_allocations.value?(compiled_arg)
              expectation_error =
                "Heap allocation slot for #{op} in #{function_name} already seen as H-#{heap_allocations.key(compiled_arg)}"
              return false
            else
              heap_allocations[variable] = compiled_arg
            end
          else
            unless compiled_arg == arg
              expectation_error =
                "Wrong arg for #{op} in #{function_name}: expected `#{arg}` at index #{index} but was `#{compiled_arg}` instead"
              return false
            end
          end
        end
      end
    end
  end

  failure_message do |source|
    if @compilation_error
      "Did not compile due to #{@compilation_error_type} error: #{@compilation_error}"
    else
      compilation_output =
        compile(source)
          .functions
          .map { |function, code| [function, "  " + code.join("\n  ")] }
          .map { |function, code| "#{function}:\n#{code}" }
          .join("\n")

      <<~ERROR
        #{expectation_error}

        Compilation output:
        #{compilation_output}
      ERROR
    end
  end
end
