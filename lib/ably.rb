require 'addressable/uri'

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
require 'ably/version'

# Allow a variant to be configured for all instances of this client library
# such as ruby-rest-[VERSION]
module Ably
  # @api private
  def self.lib_variant=(variant)
    @lib_variant = variant
  end

  def self.lib_variant
    @lib_variant
  end
end
