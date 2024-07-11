# frozen_string_literal: true

require "test_helper"

class BundleUpdateInteractiveTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::BundleUpdateInteractive::VERSION
  end

  def test_it_renders_updateable_gems
    Dir.chdir(File.expand_path("fixtures", __dir__)) do
      updated_lockfile = File.read("Gemfile.lock.updated")
      fake_changelog_locator = FakeChangelogLocator.new
      BundleUpdateInteractive::BundlerCommands.expects(:read_updated_lockfile).returns(updated_lockfile)
      BundleUpdateInteractive::ChangelogLocator.expects(:new).at_least_once.returns(fake_changelog_locator)
      # TODO: mock Bundler::Audit
      report = BundleUpdateInteractive::Report.generate

      gem_update_table = BundleUpdateInteractive::CLI::Table.new(report.updateable_gems).render
      assert_matches_snapshot(gem_update_table)
    end
  end

  class FakeChangelogLocator
    def find_changelog_uri(name:, version: nil)
      "http://example/#{name}/v#{version}"
    end
  end
end
