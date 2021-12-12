require 'bundler'
Bundler.require

$LOAD_PATH.unshift File.join(__dir__, 'lib')

require 'scanner'

use Rack::JSONBodyParser

before do
  content_type :json
end

post '/tokens' do
  source = request.params["source"]

  scanner = Scanner.new(source)

  {hello: scanner.scan.map(&:as_json)}.to_json
end
