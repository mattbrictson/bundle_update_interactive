# frozen_string_literal: true

require "mocha/api"

Mocha.configure do |config|
  config.stubbing_non_existent_method = :prevent
end

Mocha::ExpectationErrorFactory.exception_class = Megatest::Assertion

module BundleUpdateInteractive
  class Test
    include Mocha::API

    setup do
      mocha_setup
    end

    teardown do
      @__m.record_failures { mocha_verify }
      mocha_teardown
    end
  end
end
