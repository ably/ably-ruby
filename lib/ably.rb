require 'addressable/uri'

require 'ably/version'

%w(modules util).each do |namespace|
  Dir.glob(File.expand_path("ably/#{namespace}/*.rb", File.dirname(__FILE__))).sort.each do |file|
    require file
  end
end

require 'ably/auth'
require 'ably/exceptions'
require 'ably/logger'
require 'ably/realtime'
require 'ably/rest'
