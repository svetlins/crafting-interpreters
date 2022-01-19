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
  process(source).to_json
end

get '/status' do
  {
    ruby_version: RUBY_VERSION,
  }.to_json
end


def process(source)
  executable = ALox::ExecutableContainer.new
  had_error = false

  error_reporter = Object.new

  error_reporter.define_singleton_method 'method_missing' do |*|
    had_error = true
  end

  tokens = ALox::Scanner.new(source, error_reporter: error_reporter).scan
  ast = !had_error ? ALox::Parser.new(tokens, error_reporter: error_reporter).parse : nil

  unless had_error
    phase1 = ALox::StaticResolver::Phase1.new(error_reporter: error_reporter)
    phase2 = ALox::StaticResolver::Phase2.new(error_reporter: error_reporter)
    phase1.resolve(ast)
    phase2.resolve(ast)
  end

  ALox::Compiler.new(ast, executable).compile unless had_error

  {
    tokens: tokens.map(&:serialize),
    tree: ast ? TreePrinter.new(ast).print : nil,
    executable: executable&.serialize
  }
end

