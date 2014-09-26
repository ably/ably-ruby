require 'delegate'

module Ably::Rest::Models
  # A placeholder class representing a presence message
  class PresenceMessage < Delegator
    include Ably::Modules::Conversions

    def initialize(json_object)
      super
      @json_object = IdiomaticRubyWrapper(json_object.clone.freeze, stop_at: [:client_data])
    end

    def __getobj__
      @json_object
    end

    def __setobj__(obj)
      @json_object = obj
    end
  end
end
