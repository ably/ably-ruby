require 'ably/models/paginated_result'

module Ably::Models
  # HTTP respones object from Rest#request object
  # Wraps any Ably HTTP response that supports paging and provides methods to iterate through
  # the pages using {#first}, {#next}, {#has_next?} and {#last?}

  class HttpPaginatedResponse < PaginatedResult
    # Retrieve the first page of results.
    # When used as part of the {Ably::Realtime} library, it will return a {Ably::Util::SafeDeferrable} object,
    #   and allows an optional success callback block to be provided.
    #
    # @return [HttpPaginatedResponse,Ably::Util::SafeDeferrable]
    #
    def first(&success_callback)
      async_wrap_if_realtime(success_callback) do
        return nil unless supports_pagination?
        HttpPaginatedResponse.new(client.get(pagination_url('first')), base_url, client, pagination_options, &each_block)
      end
    end

    # Retrieve the next page of results.
    # When used as part of the {Ably::Realtime} library, it will return a {Ably::Util::SafeDeferrable} object,
    #   and allows an optional success callback block to be provided.
    #
    # @return [HttpPaginatedResponse,Ably::Util::SafeDeferrable]
    #
    def next(&success_callback)
      async_wrap_if_realtime(success_callback) do
        return nil unless has_next?
        HttpPaginatedResponse.new(client.get(pagination_url('next')), base_url, client, pagination_options, &each_block)
      end
    end

    # The HTTP status code of the response.
    #
    # @spec HP4
    #
    # @return [Integer]
    #
    def status_code
      http_response.status.to_i
    end

    # Whether statusCode indicates success. This is equivalent to 200 <= statusCode < 300.
    #
    # @spec HP5
    #
    # @return [Boolean]
    #
    def success?
      (200..299).include?(http_response.status.to_i)
    end

    # The error code if the X-Ably-Errorcode HTTP header is sent in the response.
    #
    # @spec HP6
    #
    # @return [Integer]
    #
    def error_code
      if http_response.headers['X-Ably-Errorcode']
        http_response.headers['X-Ably-Errorcode'].to_i
      end
    end

    # The error message if the X-Ably-Errormessage HTTP header is sent in the response.
    #
    # @spec HP7
    #
    # @return [String]
    #
    def error_message
      http_response.headers['X-Ably-Errormessage']
    end

    # The headers of the response.
    #
    # @spec HP8
    #
    # @return [Hash<String, String>]
    #
    def headers
      http_response.headers || {}
    end

    # Farady compatible response object used when an exception is raised
    # @api private
    class ErrorResponse
      def initialize(status, error_code, error_message)
        @status = status
        @error_code = error_code
        @error_message = error_message
      end

      def status
        @status
      end

      def headers
        {
          'X-Ably-Errorcode' => @error_code,
          'X-Ably-Errormessage' => @error_message
        }
      end

      def body
        nil
      end
    end
  end
end
