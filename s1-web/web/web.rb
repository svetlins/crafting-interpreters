require "rubygems"
require "bundler/setup"
Bundler.require(:default)

require_relative "tree_printer"

set :allow_origin, "*"
set :allow_methods, "GET,HEAD,POST"
set :allow_headers, "content-type,if-modified-since"
set :expose_headers, "location,link"

use Rack::JSONBodyParser

before do
  content_type :json
end

post '/analyze' do
  source = request.params["source"]

  tokens, ast, executable_container, errors = CompilationEnvironment.compile(source)

  if errors.any?
    {
      errors: errors
    }
  else
    {
      tokens: tokens.map(&:serialize),
      tree: ast ? TreePrinter.new(ast).print : nil,
      executable: executable_container&.serialize
  }
  end.to_json
end

get '/status' do
  {
    ruby_version: RUBY_VERSION,
  }.to_json
end

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

      phase1 = ALox::StaticResolver::Phase1.new(error_reporter: self)
      phase1.resolve(ast)

      throw :error if @errors.any?

      phase2 = ALox::StaticResolver::Phase2.new(error_reporter: self)
      phase2.resolve(ast)

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
