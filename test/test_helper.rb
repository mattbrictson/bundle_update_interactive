# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "bundle_update_interactive"
require "minitest/autorun"
require "mocha/minitest"

BundleUpdateInteractive.pastel = Pastel.new(enabled: true)
