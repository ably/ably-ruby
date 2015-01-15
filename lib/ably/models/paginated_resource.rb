module Ably::Models
  # Wraps any Ably HTTP response that supports paging and automatically provides methods to iterate through
  # the array of resources using {#first_page}, {#next_page}, {#first_page?} and {#last_page?}
  #
  # Paging information is provided by Ably in the LINK HTTP headers
  class PaginatedResource
    include Enumerable
    include Ably::Modules::AsyncWrapper if defined?(EventMachine)

    # @param [Faraday::Response] http_response Initial HTTP response from an Ably request to a paged resource
    # @param [String] base_url Base URL for request that generated the http_response so that subsequent paged requests can be made
    # @param [Client] client {Ably::Client} used to make the request to Ably
    # @param [Hash] options Options for this paged resource
    # @option options [Symbol,String] :coerce_into symbol or string representing class that should be used to create each item in the PaginatedResource
    #
    # @yield [Object] block will be called for each resource object for the current page.  This is a useful way to apply a transformation to any page resources after they are retrieved
    #
    # @return [PaginatedResource]
    def initialize(http_response, base_url, client, options = {}, &each_block)
      @http_response = http_response
      @client        = client
      @base_url      = "#{base_url.gsub(%r{/[^/]*$}, '')}/"
      @coerce_into   = options[:coerce_into]
      @raw_body      = http_response.body
      @each_block    = each_block
      @make_async    = options.fetch(:async_blocking_operations, false)

      @body = http_response.body
      @body = coerce_items_into(body, @coerce_into) if @coerce_into
      @body = body.map { |item| yield item } if block_given?
    end

    # Retrieve the first page of results.
    # When used as part of the {Ably::Realtime} library, it will return a {EventMachine::Deferrable} object,
    #   and allows an optional success callback block to be provided.
    #
    # @return [PaginatedResource,EventMachine::Deferrable]
    def first_page(&success_callback)
      async_wrap_if(make_async, success_callback) do
        PaginatedResource.new(client.get(pagination_url('first')), base_url, client, pagination_options, &each_block)
      end
    end

    # Retrieve the next page of results.
    # When used as part of the {Ably::Realtime} library, it will return a {EventMachine::Deferrable} object,
    #   and allows an optional success callback block to be provided.
    #
    # @return [PaginatedResource,EventMachine::Deferrable]
    def next_page(&success_callback)
      async_wrap_if(make_async, success_callback) do
        raise Ably::Exceptions::InvalidPageError, 'There are no more pages' if supports_pagination? && last_page?
        PaginatedResource.new(client.get(pagination_url('next')), base_url, client, pagination_options, &each_block)
      end
    end

    # True if this is the last page in the paged resource set
    #
    # @return [Boolean]
    def last_page?
      !supports_pagination? ||
        pagination_header('next').nil?
    end

    # True if this is the first page in the paged resource set
    #
    # @return [Boolean]
    def first_page?
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
      body[index]
    end

    # Returns number of items within this page, not the total number of items in the entire paged resource set
    def length
      body.length
    end
    alias_method :count, :length
    alias_method :size,  :length

    # Method to allow {PaginatedResource} to be {http://ruby-doc.org/core-2.1.3/Enumerable.html Enumerable}
    def each(&block)
      return to_enum(:each) unless block_given?
      body.each(&block)
    end

    # First item in this page
    def first
      body.first
    end

    # Last item in this page
    def last
      body.last
    end

    def inspect
      <<-EOF.gsub(/^        /, '')
        #<#{self.class.name}:#{self.object_id}
         @base_url="#{base_url}",
         @first_page?=#{!!first_page?},
         @last_page?=#{!!first_page?},
         @body=
           #{body.map { |item| item.inspect }.join(",\n           ") }
        >
      EOF
    end

    private
    attr_reader :body, :http_response, :base_url, :client, :coerce_into, :raw_body, :each_block, :make_async

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
      raise Ably::Exceptions::InvalidPageError, "Paging header link #{id} does not exist" unless pagination_header(id)

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

    def async_wrap_if(is_realtime, success_callback, &operation)
      if is_realtime
        raise 'EventMachine is required for asynchronous operations' unless defined?(EventMachine)
        async_wrap success_callback, &operation
      else
        yield
      end
    end
  end
end
