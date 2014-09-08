require "support/test_app"

module ApiHelper
  def app_id
    TestApp.instance.app_id
  end

  def key_id
    TestApp.instance.key_id
  end

  def api_key
    TestApp.instance.api_key
  end

  def environment
    TestApp.instance.environment
  end

  def encode64(text)
    Base64.encode64(text).gsub("\n", '')
  end
end

RSpec.configure do |config|
  config.include ApiHelper

  config.before(:suite) do
    WebMock.disable!
    TestApp.instance
  end

  config.after(:suite) do
    WebMock.disable!
    TestApp.instance.delete
  end
end
