require 'set'

module Ably
  module Util
    # Deprecation of the client constructors in favour of the Ably Pub/Sub gem factories.
    #
    # The `ably-pubsub-server` and `ably-pubsub-device` gems call the same constructors
    # internally, so they suppress the warning for the duration of the call: the caller used
    # the recommended entry point and has nothing to migrate.
    #
    # @api private
    #
    module Deprecation
      # Where this SDK is loaded from. A warning is attributed to the first frame outside
      # it, so that an entry point which delegates to a constructor — {Ably::Rest.new}, or
      # {Ably::Realtime::Client} building its REST client — still points at the caller.
      SDK_LIB_PATH = File.expand_path('../..', __dir__).freeze

      SUPPRESSED_KEY = :ably_constructor_deprecation_suppressed

      @warned = Set.new
      @warned_mutex = Mutex.new

      class << self
        # Silence the constructor deprecation warning for the duration of the block.
        #
        # This interface is only to be used by Ably-authored SDKs.
        #
        def suppress_constructor_deprecation
          previously_suppressed = Thread.current[SUPPRESSED_KEY]
          Thread.current[SUPPRESSED_KEY] = true
          yield
        ensure
          Thread.current[SUPPRESSED_KEY] = previously_suppressed
        end

        def suppressed?
          !!Thread.current[SUPPRESSED_KEY]
        end

        # Warn that using +constructor+ directly is deprecated. +replacement+ names the
        # entry points to migrate to, so that the warning says exactly what to change.
        #
        # Warns once per call site, so that a client constructed per request or in a loop
        # does not repeat the same advice for the rest of the process's life.
        #
        def warn_constructor_deprecated(constructor, replacement)
          return if suppressed?

          location = calling_location
          return unless first_warning_for?(constructor, location)

          Kernel.warn "#{location}: warning: #{constructor} is deprecated, in favour of the factory " \
                      "naming the side your application runs on. Use #{replacement}. #{constructor} " \
                      'keeps working and is not scheduled for removal.'
        end

        # Forget which call sites have already warned.
        #
        # Only for use by this SDK's own tests, which would otherwise see a warning from the
        # first run of an example and none from a retry of it.
        #
        def reset_warnings!
          @warned_mutex.synchronize { @warned.clear }
        end

        private

        # +path:lineno+ of the code to tell about the deprecation, in the format
        # `Kernel#warn`'s own `uplevel:` uses.
        def calling_location
          # 2 skips this method and #warn_constructor_deprecated, leaving the constructor first.
          # At most a couple of SDK frames follow it — a factory, or a convenience constructor —
          # so a handful of frames is enough to look at, and cheaper than the whole backtrace.
          frames = caller_locations(2, 10)
          # A frame with no absolute_path is evaluated code, so not this SDK's
          frame = frames.find { |location| !location.absolute_path.to_s.start_with?(SDK_LIB_PATH) } || frames.first
          "#{frame.path}:#{frame.lineno}"
        end

        def first_warning_for?(constructor, location)
          @warned_mutex.synchronize { !@warned.add?("#{constructor}@#{location}").nil? }
        end
      end
    end
  end
end
