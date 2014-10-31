module Ably::Models
  # Wraps any Ably HTTP response that supports paging and automatically provides methdos to iterated through
  # the array of resources using {#first}, {#next}, {#last?} and {#first?}
  #
  # Paging information is provided by Ably in the LINK HTTP headers
  class PaginatedResource
    include Enumerable

    # @param [Faraday::Response] http_response Initial HTTP response from an Ably request to a paged resource
    # @param [String] base_url Base URL for request that generated the http_response so that subsequent paged requests can be made
    # @param [Client] client {Ably::Client} used to make the request to Ably
    # @param [Hash] options Options for this paged resource
    # @option options [Symbol,String] :coerce_into symbol or string representing class that should be used to create each item in the PaginatedResource
    #
    # @return [PaginatedResource]
    def initialize(http_response, base_url, client, options = {})
      @http_response = http_response
      @client        = client
      @base_url      = "#{base_url.gsub(%r{/[^/]*$}, '')}/"
      @coerce_into   = options[:coerce_into]
      @raw_body      = http_response.body

      @body = if @coerce_into
        http_response.body.map do |item|
          Kernel.const_get(@coerce_into).new(item)
        end
      else
        http_response.body
      end
    end

    # Retrieve the first page of results
    #
    # @return [PaginatedResource]
    def first_page
      PaginatedResource.new(client.get(pagination_url('first')), base_url, client, coerce_into: coerce_into)
    end

    # Retrieve the next page of results
    #
    # @return [PaginatedResource]
    def next_page
      raise Ably::Exceptions::InvalidPageError, "There are no more pages" if supports_pagination? && last_page?
      PaginatedResource.new(client.get(pagination_url('next')), base_url, client, coerce_into: coerce_into)
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

    # Method ensuring this {PaginatedResource} is {http://ruby-doc.org/core-2.1.3/Enumerable.html Enumerable}
    def each(&block)
      body.each do |item|
        if block_given?
          block.call item
        else
          yield item
        end
      end
    end

    # Last item in this page
    def first
      body.first
    end

    # Last item in this page
    def last
      body.last
    end

    private
    attr_reader :body, :http_response, :base_url, :client, :coerce_into, :raw_body

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
  end
end
