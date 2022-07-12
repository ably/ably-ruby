# frozen_string_literal: true

module Ably
  module Models
    # When Log Level set to none, this NilLogger is used to silence all logging
    # NilLogger provides a Ruby Logger compatible interface
    class NilLogger
      def null_method(*_args)
      end

      def level
        :none
      end

      def level=(_value)
        level
      end

      %I[fatal error warn info debug].each do |method|
        alias_method method, :null_method
      end
    end
  end
end
