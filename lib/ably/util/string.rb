# frozen_string_literal: true

module Ably::Util
    module String
        def self.is_null_or_empty(str)
        str.nil? || str.empty?
        end
    end
end
