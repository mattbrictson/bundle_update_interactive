# frozen_string_literal: true

require "test_helper"
require "openssl"
require "net/http"

module BundleUpdateInteractive
  class HttpTest < Minitest::Test
    def test_gracefully_handles_openssl_error
      Net::HTTP.stubs(:start).raises(OpenSSL::SSL::SSLError)

      result = HTTP.get("https://example.test/")

      refute_predicate result, :success?
      assert_nil result.code
      assert_instance_of OpenSSL::SSL::SSLError, result.exception
    end
  end
end
