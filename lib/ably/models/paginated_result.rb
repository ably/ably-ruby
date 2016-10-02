module Ably::Models
  # Wraps any Ably HTTP response that supports paging and provides methods to iterate through
  # the pages using {#first}, {#next}, {#has_next?} and {#last?}
  #
  # All items in the HTTP response are available in the Array returned from {#items}
  #
  # Paging information is provided by Ably in the LINK HTTP headers
  #
  class PaginatedResult
    include Ably::Modules::AsyncWrapper if defined?(Ably::Realtime)

    # The items contained within this {PaginatedResult}
    # @return [Array]
    attr_reader :items

    # @param [Faraday::Response] http_response Initial HTTP response from an Ably request to a paged resource
    # @param [String] base_url Base URL for request that generated the http_response so that subsequent paged requests can be made
    # @param [Client] client {Ably::Client} used to make the request to Ably
    # @param [Hash] options Options for this paged resource
    # @option options [Symbol,String] :coerce_into symbol or string representing class that should be used to create each item in the PaginatedResult
    #
    # @yield [Object] block will be called for each resource object for the current page.  This is a useful way to apply a transformation to any page resources after they are retrieved
    #
    # @return [PaginatedResult]
    def initialize(http_response, base_url, client, options = {}, &each_block)
      @http_response = http_response
      @client        = client
      @base_url      = "#{base_url.gsub(%r{/[^/]*$}, '')}/"
      @coerce_into   = options[:coerce_into]
      @raw_body      = http_response.body
      @each_block    = each_block
      @make_async    = options.fetch(:async_blocking_operations, false)

      @items = http_response.body
      if @items.nil? || @items.to_s.strip.empty?
        @items = []
      end
      @items = [@items] if @items.kind_of?(Hash)

      @items = coerce_items_into(items, @coerce_into) if @coerce_into
      @items = items.map { |item| yield item } if block_given?
    end

    # Retrieve the first page of results.
    # When used as part of the {Ably::Realtime} library, it will return a {Ably::Util::SafeDeferrable} object,
    #   and allows an optional success callback block to be provided.
    #
    # @return [PaginatedResult,Ably::Util::SafeDeferrable]
    def first(&success_callback)
      async_wrap_if_realtime(success_callback) do
        return nil unless supports_pagination?
        PaginatedResult.new(client.get(pagination_url('first')), base_url, client, pagination_options, &each_block)
      end
    end

    # Retrieve the next page of results.
    # When used as part of the {Ably::Realtime} library, it will return a {Ably::Util::SafeDeferrable} object,
    #   and allows an optional success callback block to be provided.
    #
    # @return [PaginatedResult,Ably::Util::SafeDeferrable]
    def next(&success_callback)
      async_wrap_if_realtime(success_callback) do
        return nil unless has_next?
        PaginatedResult.new(client.get(pagination_url('next')), base_url, client, pagination_options, &each_block)
      end
    end

    # True if this is the last page in the paged resource set
    #
    # @return [Boolean]
    def last?
      !supports_pagination? ||
        pagination_header('next').nil?
    end

    # True if there is a subsequent page in this paginated set available with {#next}
    #
    # @return [Boolean]
    def has_next?
      supports_pagination? && !last?
    end

    # True if the HTTP response supports paging with the expected LINK HTTP headers
    #
    # @return [Boolean]
    def supports_pagination?
      !pagination_headers.empty?
    end

    def inspect
      <<-EOF.gsub(/^        /, '')
        #<#{self.class.name}:#{self.object_id}
         @base_url="#{base_url}",
         @last?=#{!!last?},
         @has_next?=#{!!has_next?},
         @items=
           #{items.map { |item| item.inspect }.join(",\n           ") }
        >
      EOF
    end

    private
    def http_response
      @http_response
    end

    def base_url
      @base_url
    end

    def client
      @client
    end

    def coerce_into
      @coerce_into
    end

    def raw_body
      @raw_body
    end

    def each_block
      @each_block
    end

    def make_async
      @make_async
    end

    def coerce_items_into(items, type_string)
      items.map do |item|
        @coerce_into.split('::').inject(Kernel) do |base, klass_name|
          base.public_send(:const_get, klass_name)
        end.new(item)
      end
    end

    def pagination_headers
      link_regex = %r{<(?<url>[^>]+)>; rel="(?<rel>[^"]+)"}
      @pagination_headers ||= begin
        # All `Link:` headers are concatenated by Faraday into a comma separated list
        # Finding matching `<url>; rel="rel"` pairs
        link_headers = http_response.headers['link'] || ''
        link_headers.scan(link_regex).each_with_object({}) do |val_array, hash|
          url, rel = val_array
          hash[rel] = url
        end
      end
    end

    def pagination_header(id)
      pagination_headers[id]
    end

    def pagination_url(id)
      raise Ably::Exceptions::PageMissing, "Paging header link #{id} does not exist" unless pagination_header(id)

      if pagination_header(id).match(%r{^\./})
        "#{base_url}#{pagination_header(id)[2..-1]}"
      else
        pagination_header[id]
      end
    end

    def pagination_options
      {
        coerce_into: coerce_into,
        async_blocking_operations: make_async
      }
    end

    def async_wrap_if_realtime(success_callback, &operation)
      if make_async
        raise 'EventMachine is required for asynchronous operations' unless defined?(EventMachine)
        async_wrap success_callback, &operation
      else
        yield
      end
    end

    def logger
      client.logger
    end
  end
end
