require "spec_helper"

module ALox
  RSpec.describe "language test suite" do
    def execute(source)
      tokens = Scanner.new(source).scan
      ast = Parser.new(tokens).parse
      executable = ExecutableContainer.new

      phase1 = StaticResolver::Phase1.new
      phase2 = StaticResolver::Phase2.new
      phase1.resolve(ast)
      phase2.resolve(ast)

      Compiler.new(ast, executable).compile

      stdout = StringIO.new

      VM.execute(executable, out: stdout)

      stdout.tap(&:rewind).read.chomp
    end

    Dir["#{File.dirname(__FILE__)}/../../test_suite/**/*.lox"].each do |test_file|
      test_name = File.basename(test_file).chomp(".lox")

      specify "(#{test_name})" do
        source = File.read(test_file)

        expected_output =
          source
            .lines
            .select { _1.include?("// => ") }
            .map { _1[/\/\/ => (.*)/, 1] }
            .join("\n")

        expect(execute(source)).to eq(expected_output)
      end
    end
  end
end
