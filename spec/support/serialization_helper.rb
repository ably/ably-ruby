module SerializationHelper
  def serialize_body(object, protocol)
    if protocol == :msgpack
      MessagePack.pack(object)
    else
      JSON.dump(object)
    end
  end

  def deserialize_body(object, protocol)
    if protocol == :msgpack
      MessagePack.unpack(object)
    else
      JSON.parse(object)
    end
  end

  RSpec.configure do |config|
    config.include self
  end
end
