# frozen_string_literal: true

require "net/http"
require "uri"

module BundleUpdateInteractive
  module HTTP
    module Success
      def success?
        code.start_with?("2")
      end
    end

    class << self
      def get(url)
        http(:get, url)
      end

      def head(url)
        http(:head, url)
      end

      private

      def http(method, url_string)
        uri = URI(url_string)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme.end_with?("s")) do |http|
          http.public_send(method, uri.request_uri)
        end
        response.extend(Success)
      end
    end
  end
end
