require 'spec_helper'
require "support/protocol_msgbus_helper"

describe Ably::Realtime::Client do
  subject do
    Ably::Realtime::Client.new('appid.keyuid:keysecret')
  end
end
