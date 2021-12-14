require 'sinatra'
require 'sinatra/cors'
require 'rack/contrib'

$LOAD_PATH.unshift File.join(__dir__, 'lib')

require 'scanner'
require 'parser'
require 'printers/tree_printer'

set :allow_origin, "*"
set :allow_methods, "GET,HEAD,POST"
set :allow_headers, "content-type,if-modified-since"
set :expose_headers, "location,link"

use Rack::JSONBodyParser

before do
  content_type :json
end

post '/api/analyze' do
  source = request.params["source"]

  tokens = Scanner.new(source).scan
  tree = TreePrinter.print(Parser.new(tokens).parse)

  {tokens: tokens.map(&:as_json), tree: tree}.to_json
end
