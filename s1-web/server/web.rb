require 'sinatra'
require 'sinatra/cors'
require 'rack/contrib'

$LOAD_PATH.unshift File.join(__dir__, 'lib')

require 'scanner'
require 'parser'
require 'static_resolver'
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

  tree = TreePrinter.new(ast, resolver.resolutions).print

  {tokens: tokens.map(&:as_json), tree: tree}.to_json
end
