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
