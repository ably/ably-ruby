# frozen_string_literal: true

module Ably
  module Modules
    # @api private
    module StatesmanMonkeyPatch
      # Override Statesman's #before_transition to support :from arrays
      # This can be removed once https://github.com/gocardless/statesman/issues/95 is solved
      def before_transition(options = nil, &block)
        arrayify_transition(options) do |options_without_from_array|
          super(*options_without_from_array, &block)
        end
      end

      # Override Statesman's #after_transition to support :from arrays
      # This can be removed once https://github.com/gocardless/statesman/issues/95 is solved
      def after_transition(options = nil, &block)
        arrayify_transition(options) do |options_without_from_array|
          super(*options_without_from_array, &block)
        end
      end

      private

      def arrayify_transition(options, &_block)
        if options.nil?
          yield []
        elsif options.fetch(:from, nil).is_a?(Array)
          options[:from].each do |from_state|
            yield [options.merge(from: from_state)]
          end
        else
          yield [options]
        end
      end
    end
  end
end
