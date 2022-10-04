module Ably
  VERSION = '1.2.3'
  PROTOCOL_VERSION = '1.2'

  # @api private
  def self.major_minor_version_numeric
    VERSION.gsub(/\.\d+$/, '').to_f
  end
end
