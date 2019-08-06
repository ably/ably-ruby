module Ably
  VERSION = '1.1.2'
  PROTOCOL_VERSION = '1.1'

  # Allow a variant to be configured for all instances of this client library
  # such as ruby-rest-[VERSION]

  # @api private
  def self.lib_variant=(variant)
    @lib_variant = variant
  end

  def self.lib_variant
    @lib_variant
  end

  # @api private
  def self.major_minor_version_numeric
    VERSION.gsub(/\.\d+$/, '').to_f
  end
end
