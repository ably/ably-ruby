module Ably
  module Rest
    class PagedResource
      include Enumerable

      def initialize(http_response, base_url, client)
        @http_response = http_response
        @body          = http_response.body
        @client        = client
        @base_url      = "#{base_url.gsub(%r{/[^/]*$}, '')}/"
      end

      def first
        PagedResource.new(@client.get(pagination_url('first')), @base_url, @client)
      end

      def next
        PagedResource.new(@client.get(pagination_url('next')), @base_url, @client)
      end

      def last?
        pagination_header('next').nil?
      end

      def first?
        pagination_header('first') == pagination_header('current')
      end

      def pagination_header(id)
        link_regex = %r{<(?<url>[^>]+)>; rel="(?<rel>[^"]+)"}
        @link_headers ||= @http_response.headers['link'].scan(link_regex).inject({}) do |hash, val_array|
          url, rel = val_array
          hash[rel] = url
          hash
        end

        @link_headers[id]
      end

      def pagination_url(id)
        raise InvalidPageError, "Paging heading link #{id} does not exist" unless pagination_header(id)

        if pagination_header(id).match(%r{^\./})
          "#{@base_url}#{pagination_header(id)[2..-1]}"
        else
          pagination_header[id]
        end
      end

      def [](index)
        @body[index]
      end

      def length
        @body.length
      end
      alias_method :count, :length
      alias_method :size,  :length

      def count
        @body.count
      end

      def each(&block)
        @body.each do |item|
          if block_given?
            block.call item
          else
            yield item
          end
        end
      end
    end
  end
end
