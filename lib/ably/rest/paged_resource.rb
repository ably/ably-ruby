module Ably
  module Rest
    # Wraps any Ably HTTP response that supports paging and automatically provides methdos to iterated through
    # the array of resources using {#first}, {#next}, {#last?} and {#first?}
    #
    # Paging information is provided by Ably in the LINK HTTP headers
    class PagedResource
      include Enumerable

      # @param [Faraday::Response] http_response Initial HTTP response from an Ably request to a paged resource
      # @param [String] base_url Base URL for request that generated the http_response so that subsequent paged requests can be made
      # @param [Ably::Rest::Client] client {Ably::Client} used to make the request to Ably
      # @param [Hash] options Options for this paged resource
      # @option options [Symbol] :coerce_into symbol representing class that should be used to represent each item in the PagedResource
      #
      # @return [Ably::Rest::PagedResource]
      def initialize(http_response, base_url, client, coerce_into: nil)
        @http_response = http_response
        @client        = client
        @base_url      = "#{base_url.gsub(%r{/[^/]*$}, '')}/"
        @coerce_into   = coerce_into

        @body = if coerce_into
          http_response.body.map do |item|
            Kernel.const_get(coerce_into).new(item)
          end
        else
          http_response.body
        end
      end

      # Retrieve the first page of results
      #
      # @return [Ably::Rest::PagedResource]
      def first
        PagedResource.new(@client.get(pagination_url('first')), @base_url, @client, coerce_into: @coerce_into)
      end

      # Retrieve the next page of results
      #
      # @return [Ably::Rest::PagedResource]
      def next
        PagedResource.new(@client.get(pagination_url('next')), @base_url, @client, coerce_into: @coerce_into)
      end

      # True if this is the last page in the paged resource set
      #
      # @return [Boolean]
      def last?
        !supports_pagination? ||
          pagination_header('next').nil?
      end

      # True if this is the first page in the paged resource set
      #
      # @return [Boolean]
      def first?
        !supports_pagination? ||
          pagination_header('first') == pagination_header('current')
      end

      # True if the HTTP response supports paging with the expected LINK HTTP headers
      #
      # @return [Boolean]
      def supports_pagination?
        !pagination_headers.empty?
      end

      # Standard Array accessor method
      def [](index)
        @body[index]
      end

      # Returns number of items within this page, not the total number of items in the entire paged resource set
      def length
        @body.length
      end
      alias_method :count, :length
      alias_method :size,  :length

      # Method ensuring this {Ably::Rest::PagedResource} is {http://ruby-doc.org/core-2.1.3/Enumerable.html Enumerable}
      def each(&block)
        @body.each do |item|
          if block_given?
            block.call item
          else
            yield item
          end
        end
      end

      private
      def pagination_headers
        link_regex = %r{<(?<url>[^>]+)>; rel="(?<rel>[^"]+)"}
        @pagination_headers ||= @http_response.headers['link'].scan(link_regex).inject({}) do |hash, val_array|
          url, rel = val_array
          hash[rel] = url
          hash
        end
      end

      def pagination_header(id)
        pagination_headers[id]
      end

      def pagination_url(id)
        raise Ably::Exceptions::InvalidPageError, "Paging heading link #{id} does not exist" unless pagination_header(id)

        if pagination_header(id).match(%r{^\./})
          "#{@base_url}#{pagination_header(id)[2..-1]}"
        else
          pagination_header[id]
        end
      end
    end
  end
end
