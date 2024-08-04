# frozen_string_literal: true

require "test_helper"
require "bundler"
require "bundler/audit"
require "bundler/audit/scanner"

module BundleUpdateInteractive
  class ReportTest < Minitest::Test
    def test_generate_creates_a_report_of_updatable_gems_that_can_be_rendered_as_a_table
      VCR.use_cassette("changelog_requests") do
        Dir.chdir(File.expand_path("../fixtures", __dir__)) do
          updated_lockfile = File.read("Gemfile.lock.updated")
          BundlerCommands.expects(:read_updated_lockfile).with(level: nil).returns(updated_lockfile)
          mock_vulnerable_gems("actionpack", "rexml", "devise")

          report = Report.generate
          report.scan_for_vulnerabilities!

          gem_update_table = CLI::Table.new(report.updateable_gems).render
          assert_matches_snapshot(gem_update_table)
        end
      end
    end

    def test_generate_creates_a_report_of_updatable_gems_for_development_and_test_groups
      VCR.use_cassette("changelog_requests") do # rubocop:disable Metrics/BlockLength
        Dir.chdir(File.expand_path("../fixtures", __dir__)) do
          updated_lockfile = File.read("Gemfile.lock.development-test-updated")
          BundlerCommands.expects(:read_updated_lockfile).with(
            *%w[
              addressable
              bindex
              capybara
              debug
              matrix
              public_suffix
              regexp_parser
              rexml
              rubyzip
              selenium-webdriver
              web-console
              websocket
              xpath
            ],
            level: nil
          ).returns(updated_lockfile)
          mock_vulnerable_gems("actionpack", "rexml", "devise")

          report = Report.generate(groups: %i[development test])
          report.scan_for_vulnerabilities!

          gem_update_table = CLI::Table.new(report.updateable_gems).render
          assert_matches_snapshot(gem_update_table)
        end
      end
    end

    def test_generate_returns_empty_report_when_given_non_existent_group
      Dir.chdir(File.expand_path("../fixtures", __dir__)) do
        report = Report.generate(groups: [:assets])

        assert_empty report.updateable_gems
      end
    end
  end
end
