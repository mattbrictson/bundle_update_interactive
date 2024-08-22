# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "bundle_update_interactive"
require "minitest/autorun"

BundleUpdateInteractive.pastel = Pastel.new(enabled: true)

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |rb| require(rb) }
