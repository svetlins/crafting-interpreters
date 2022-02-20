unless RUBY_PLATFORM == "opal"
  puts "This file is only supposed to be used with the Opal Ruby -> JS transpiler"
  exit(1)
end

require "corelib/array/pack"
require "corelib/string/unpack"
require "json"
require_relative "a_lox"

class CompilationEnvironment
  def self.compile(source)
    new.compile(source)
  end

  def compile(source)
    @errors = []

    tokens, ast, executable_container = nil, nil, nil

    catch :error do
      executable_container = ALox::ExecutableContainer.new

      tokens = ALox::Scanner.new(source, error_reporter: self).scan
      throw :error if @errors.any?

      ast = ALox::Parser.new(tokens, error_reporter: self).parse

      throw :error if @errors.any?

      ALox::StaticResolver::Upvalues.new(error_reporter: self).resolve(ast)

      throw :error if @errors.any?

      ALox::Compiler.new(ast, executable_container).compile
    end

    [tokens, ast, executable_container, @errors]
  end

  def report_scanner_error(line, message)
    @errors << "scanner error. line: #{line} - error: #{message}"
  end

  def report_parser_error(token, message)
    if token.type == ALox::TokenTypes::EOF
      @errors << "parser error. line: #{token.line} at end - error: #{message}"
    else
      @errors << "parser error. line: #{token.line}, token: #{token.lexeme} - error: #{message}"
    end

  end

  def report_static_analysis_error(token, message)
    @errors << "static analysis error. line: #{token.line} - error: #{message}"
  end

  def report_runtime_error(message)
    @errors << "runtime error: #{message}"
  end
end

module ALox
  def self.analyze(source)
    tokens, ast, executable_container, errors = CompilationEnvironment.compile(source)

    if errors.any?
      {
        errors: errors
      }
    else
      {
        tokens: tokens.map(&:serialize),
        tree: ast ? Printers::ReactTreePrinter.new(ast).print : nil,
        executable: executable_container&.serialize
    }
    end.to_json
  end
end



