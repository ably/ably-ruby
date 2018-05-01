module Ably
  VERSION = '1.0.6'
  PROTOCOL_VERSION = '1.0'

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
