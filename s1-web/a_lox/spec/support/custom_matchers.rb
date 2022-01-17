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
    executable = ALox::Executable.new

    phase1 = ALox::StaticResolver::Phase1.new(error_reporter: self)
    phase2 = ALox::StaticResolver::Phase2.new(error_reporter: self)
    phase1.resolve(ast)
    phase2.resolve(ast)
    return if @compilation_error

    ALox::Compiler.new(ast, executable, error_reporter: self).compile
    return if @compilation_error

    executable
  end

  expected_executable =
    expected.lines
      .map(&:chomp)
      .map(&:strip)
      .chunk { _1.end_with?(":") }
      .map { _1.last }
      .each_slice(2)
      .map { [_1.first.first.chomp(":") ,_1.last] }
      .to_h

  expectation_error = nil

  match do |source|
    executable = compile(source)

    return false unless executable

    expected_executable.each do |function_name, ops|
      compiled_function = executable.functions[function_name].map(&:to_s)

      ops.each_with_index do |op, index|
        op, *args = op.split(/\s/)
        compiled_op = compiled_function.shift

        unless compiled_op == op
          expectation_error =
            "Wrong op in #{function_name}: expected #{op} at index #{index} but was #{compiled_op} instead"
          return false
        end

        args.each do |arg|
          compiled_arg = compiled_function.shift
          unless compiled_arg == arg
            expectation_error =
              "Wrong arg in #{function_name}: expected `#{arg}` at index #{index} but was `#{compiled_arg}` instead"
            return false
          end
        end
      end
    end
  end

  failure_message do |source|
    if @compilation_error
      "Did not compile due to #{@compilation_error_type} error: #{@compilation_error}"
    else
      expectation_error
    end
  end
end
