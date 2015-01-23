require 'support/test_app'

module ApiHelper
  def app_id
    TestApp.instance.app_id
  end

  def key_id
    TestApp.instance.key_id
  end

  def key_secret
    api_key.split(':')[1]
  end

  def api_key
    TestApp.instance.api_key
  end

  def restricted_api_key
    TestApp.instance.restricted_api_key
  end

  def environment
    TestApp.instance.environment
  end

  def reload_test_app
    WebMock.disable!
    TestApp.reload
  end

  def encode64(text)
    Base64.encode64(text).gsub("\n", '')
  end
end

RSpec.configure do |config|
  config.include ApiHelper

  config.before(:suite) do
    WebMock.disable!
  end

  config.after(:suite) do
    WebMock.disable!
    TestApp.instance.delete
  end
end

module ApiPreloader
  def self.included(mod)
    WebMock.disable!
    TestApp.instance.api_key
  end

  RSpec.configure do |config|
    config.include self, :file_path => %r(spec/acceptance)
  end
end
