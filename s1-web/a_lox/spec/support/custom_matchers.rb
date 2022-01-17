RSpec::Matchers.define :compile_to do |expected|
  def compile(source)
    tokens = ALox::Scanner.new(source).scan
    ast = ALox::Parser.new(tokens).parse
    executable = ALox::Executable.new

    phase1 = ALox::StaticResolver::Phase1.new(error_reporter: self)
    phase2 = ALox::StaticResolver::Phase2.new(error_reporter: self)
    phase1.resolve(ast)
    phase2.resolve(ast)

    ALox::Compiler.new(ast, executable).compile

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

  difference_index    = nil
  difference_function = nil
  difference_op       = nil

  match do |source|
    executable = compile(source)

    if executable.functions.keys != expected_executable.keys
      false
    else
      expected_executable.each do |function_name, ops|
        compiled_function = executable.functions[function_name].map(&:to_s)

        ops.each_with_index do |op, index|
          op, *args = op.split(/\s/)

          unless compiled_function.shift == op
            difference_index = index
            difference_op = op
            difference_function = function_name
            return false
          end

          args.each do |arg|
            return false unless compiled_function.shift == arg
          end
        end
      end
    end
  end

  failure_message do |source|
    "Wrong op in #{difference_function}: expected #{difference_op} at index #{difference_index} but did not find it"
  end
end
