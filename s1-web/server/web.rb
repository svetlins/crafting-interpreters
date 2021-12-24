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

  tokens = Scanner.new(source).scan
  ast = Parser.new(tokens).parse

  resolver = StaticResolver.new(error_reporter: self)
  resolver.resolve(ast)

  tree = TreePrinter.new(ast).print

  bytecode = Compiler.new(ast).compile rescue nil

  {tokens: tokens.map(&:as_json), tree: tree, bytecode: bytecode&.as_json}.to_json
end
