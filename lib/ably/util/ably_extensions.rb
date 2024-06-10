# frozen_string_literal: true

module Ably::Util
  module AblyExtensions
    refine Object do
      def nil_or_empty?
        self.nil? || self.empty?
      end
    end

    refine Hash do
      def fetch_or_default(key, default)
        value = self.fetch(key, default)
        if value.nil?
          return default
        end
        return value
      end
    end
  end
end
