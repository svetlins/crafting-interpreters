require 'sinatra'
require "sinatra/reloader" if development?
require 'sinatra/cors'
require 'rack/contrib'

$LOAD_PATH.unshift File.join(__dir__, 'lib')

require 'scanner'
require 'parser'
require 'static_resolver'
require 'compiler'
require 'printers/tree_printer'

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
  executable = Executable.new
  had_error = false

  error_reporter = Object.new

  error_reporter.define_singleton_method 'method_missing' do |*|
    had_error = true
  end

  tokens = Scanner.new(source, error_reporter: error_reporter).scan
  ast = !had_error ? Parser.new(tokens, error_reporter: error_reporter).parse : nil

  unless had_error
    phase1 = ::StaticResolver::Phase1.new(error_reporter: error_reporter)
    phase2 = ::StaticResolver::Phase2.new(error_reporter: error_reporter)
    phase1.resolve(ast)
    phase2.resolve(ast)
  end

  Compiler.new(ast, executable).compile unless had_error

  {
    tokens: tokens.map(&:as_json),
    tree: ast ? TreePrinter.new(ast).print : nil,
    executable: executable&.as_json
  }
end

