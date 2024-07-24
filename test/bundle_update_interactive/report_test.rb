# frozen_string_literal: true

require "test_helper"
require "bundler"
require "bundler/audit"
require "bundler/audit/scanner"

module BundleUpdateInteractive
  class ReportTest < Minitest::Test
    def test_generate_creates_a_report_of_updatable_gems_that_can_be_rendered_as_a_table
      use_vcr_cassette("test_generate_creates_a_report_of_updatable_gems_that_can_be_rendered_as_a_table") do
        Dir.chdir(File.expand_path("../fixtures", __dir__)) do
          updated_lockfile = File.read("Gemfile.lock.updated")
          BundlerCommands.expects(:read_updated_lockfile).with.returns(updated_lockfile)
          mock_vulnerable_gems("actionpack", "rexml", "devise")

          report = Report.generate
          report.scan_for_vulnerabilities!

          gem_update_table = CLI::Table.new(report.updateable_gems).render
          assert_matches_snapshot(gem_update_table)
        end
      end
    end
  end
end
