module Ably
  VERSION = '0.8.14'
  PROTOCOL_VERSION = '0.8'

  # Allow a variant to be configured for all instances of this client library
  # such as ruby-rest-[VERSION]

  # @api private
  def self.lib_variant=(variant)
    @lib_variant = variant
  end

  def self.lib_variant
    @lib_variant
  end
end
