require 'bundler'
Bundler.require

$LOAD_PATH.unshift File.join(__dir__, 'lib')

require 'scanner'
require 'parser'

set :allow_origin, "*"
set :allow_methods, "GET,HEAD,POST"
set :allow_headers, "content-type,if-modified-since"
set :expose_headers, "location,link"

use Rack::JSONBodyParser

before do
  content_type :json
end

post '/tokens' do
  source = request.params["source"]

  tokens = Scanner.new(source).scan
  tree = Parser.new(tokens).parse

  sleep 1

  {tokens: tokens.map(&:as_json), tree: tree.map(&:as_json)}.to_json
end
