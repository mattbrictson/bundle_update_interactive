# frozen_string_literal: true

require "bundle_update_interactive"

BundleUpdateInteractive.pastel = Pastel.new(enabled: true)

module BundleUpdateInteractive
  class Test < Megatest::Test
  end
end

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |rb| require(rb) }
