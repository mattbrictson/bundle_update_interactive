# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = false
  config.cassette_library_dir = File.expand_path("../cassettes", __dir__)
  config.hook_into :webmock
  config.default_cassette_options = {
    match_requests_on: %i[method uri body_as_json],
    record: :once,
    record_on_error: false
  }
end

module UseVCRCassette
  private

  def use_vcr_cassette(name, options={}, &block)
    class_parts = self.class.name.split("::")
    cassette_path = [*class_parts.map { |s| s.gsub(/[^A-Z0-9]+/i, "_") }, name].join("/")

    VCR.use_cassette(cassette_path, options, &block)
  end
end

Minitest::Test.include(UseVCRCassette)
