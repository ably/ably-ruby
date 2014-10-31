%w(modules util).each do |namespace|
  Dir.glob(File.expand_path("ably/#{namespace}/*.rb", File.dirname(__FILE__))).each do |file|
    require file
  end
end

require "ably/auth"
require "ably/exceptions"
require "ably/realtime"
require "ably/rest"
require "ably/version"

# Ably is the base namespace for the Ably {Ably::Realtime Realtime} & {Ably::Rest Rest} client libraries.
#
# Please refer to the {file:README.md Readme} on getting started.
#
# @see file:README.md README
module Ably
end
