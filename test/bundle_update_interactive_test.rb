# frozen_string_literal: true

require "test_helper"

class BundleUpdateInteractiveTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::BundleUpdateInteractive::VERSION
  end

  def test_it_renders_updateable_gems
    use_vcr_cassette("test_it_renders_updateable_gems") do
      Dir.chdir(File.expand_path("fixtures", __dir__)) do
        updated_lockfile = File.read("Gemfile.lock.updated")
        BundleUpdateInteractive::BundlerCommands.expects(:read_updated_lockfile).returns(updated_lockfile)
        # TODO: mock Bundler::Audit
        report = BundleUpdateInteractive::Report.generate

        gem_update_table = BundleUpdateInteractive::CLI::Table.new(report.updateable_gems).render
        assert_matches_snapshot(gem_update_table)
      end
    end
  end
end
