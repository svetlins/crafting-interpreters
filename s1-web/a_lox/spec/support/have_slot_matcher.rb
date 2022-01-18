RSpec::Matchers.define :have_slot do |expected_slot, at:|
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

  def analyze(source)
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

    ast
  end

  match do |source|
    ast = analyze(source)

    current_node = ast

    at.split('.').each do |path_segment|
      if path_segment =~ /\d+/
        current_node = current_node[path_segment.to_i]
      else
        current_node = current_node.public_send(path_segment)
      end
    end

    current_node.allocation.slot == expected_slot
  end

  failure_message do |actual|
    "tough :("
  end
end
