##
# Run after any change of the examples in the suite and before check in

require "bundler/inline"
require "fileutils"
require "json"

gemfile do
  gem "a_lox", path: "../a_lox"
end

def compile(source)
  executable_container = ALox::ExecutableContainer.new
  tokens = ALox::Scanner.new(source).scan
  ast = ALox::Parser.new(tokens).parse
  phase1 = ALox::StaticResolver::Phase1.new
  phase1.resolve(ast)
  phase2 = ALox::StaticResolver::Phase2.new
  phase2.resolve(ast)

  ALox::Compiler.new(ast, executable_container).compile

  executable_container
end

FileUtils.mkdir_p("compiled")

Dir["*.lox"].each do |test_file_name|
  test_file_contents = File.read(test_file_name)
  compiled_file_path = "compiled/#{test_file_name}.json"
  expected_output = test_file_contents.scan(/\/\/ => (.+)$/).join("\n")

  File.open(compiled_file_path, "w") do |file|
    executable = compile(test_file_contents).serialize

    file.write({
      executable: executable,
      expected_output: expected_output
    }.to_json)
  end
end
