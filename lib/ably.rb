%w(modules models util).each do |namespace|
  Dir.glob(File.expand_path("ably/#{namespace}/*.rb", File.dirname(__FILE__))).each do |file|
    require file
  end
end

require "ably/auth"
require "ably/exceptions"
require "ably/realtime"
require "ably/rest"
require "ably/token"
require "ably/version"

module Ably
end
