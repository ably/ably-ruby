require 'securerandom'

module RandomHelper
  def random_str(length = 16)
    SecureRandom.hex(length).encode(Encoding::UTF_8)
  end

  def random_int_str(size = 1_000_000_000)
    SecureRandom.random_number(size).to_s.encode(Encoding::UTF_8)
  end

  RSpec.configure do |config|
    config.include self
  end
end
