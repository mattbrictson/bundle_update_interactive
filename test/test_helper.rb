# frozen_string_literal: true

require "bundle_update_interactive"

BundleUpdateInteractive.pastel = Pastel.new(enabled: true)

module BundleUpdateInteractive
  class Test < Megatest::Test
    private

    def within_fixture_copy(fixture=".", &block)
      fixture_path = File.join(File.expand_path("fixtures", __dir__), fixture)
      Dir.mktmpdir do |tmp|
        FileUtils.cp_r(fixture_path, tmp)
        Dir.chdir(File.join(tmp, File.basename(fixture_path)), &block)
      end
    end
  end
end

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |rb| require(rb) }
