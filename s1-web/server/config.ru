require 'bundler/setup'
Bundler.require(:default)

require File.join(File.dirname(__FILE__), "web")


map "/" do
    run LoxWeb
end
