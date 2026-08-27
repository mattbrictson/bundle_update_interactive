# frozen_string_literal: true

require "webmock"

WebMock.enable!
WebMock::AssertionFailure.error_class = Megatest::Assertion

module BundleUpdateInteractive
  class Test
    include WebMock::API

    teardown do
      WebMock.reset!
    end
  end
end
