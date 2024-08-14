# frozen_string_literal: true

require "test_helper"
require "bundler"
require "bundler/audit"
require "bundler/audit/scanner"

module BundleUpdateInteractive
  class ReporterTest < Minitest::Test
    def test_generates_a_report_of_updatable_gems_that_can_be_rendered_as_a_table
      VCR.use_cassette("changelog_requests") do
        Dir.chdir(File.expand_path("../fixtures", __dir__)) do
          updated_lockfile = File.read("Gemfile.lock.updated")
          BundlerCommands.expects(:parse_outdated).returns({})
          BundlerCommands.expects(:read_updated_lockfile).with.returns(updated_lockfile)
          mock_vulnerable_gems("actionpack", "rexml", "devise")

          report = Reporter.new.generate_report
          report.scan_for_vulnerabilities!

          gem_update_table = CLI::Table.updatable(report.updatable_gems).render
          assert_matches_snapshot(gem_update_table)
        end
      end
    end

    def test_generates_a_report_of_withheld_gems_based_on_pins_that_excludes_updatable_gems
      VCR.use_cassette("changelog_requests") do
        Dir.chdir(File.expand_path("../fixtures", __dir__)) do
          updated_lockfile = File.read("Gemfile.lock.updated")
          BundlerCommands.expects(:read_updated_lockfile).with.returns(updated_lockfile)

          # Although sqlite3 is a pinned gem, it is updatable and thus excluded from the outdated check.
          # Therefore puma is the only pinned gem to check.
          BundlerCommands.expects(:parse_outdated).with("puma").returns({ "puma" => "7.0.1" })

          report = Reporter.new.generate_report

          withheld_table = CLI::Table.withheld(report.withheld_gems).render
          assert_matches_snapshot(withheld_table)
        end
      end
    end

    def test_generates_a_report_of_updatable_gems_for_development_and_test_groups
      VCR.use_cassette("changelog_requests") do
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
            ]
          ).returns(updated_lockfile)
          mock_vulnerable_gems("actionpack", "rexml", "devise")

          # The development and test groups don't contain pinned gems, so the outdated check is skipped.
          BundlerCommands.expects(:parse_outdated).never

          report = Reporter.new(groups: %i[development test]).generate_report
          report.scan_for_vulnerabilities!

          gem_update_table = CLI::Table.updatable(report.updatable_gems).render
          assert_matches_snapshot(gem_update_table)
        end
      end
    end

    def test_generates_empty_report_when_given_non_existent_group
      Dir.chdir(File.expand_path("../fixtures", __dir__)) do
        report = Reporter.new(groups: [:assets]).generate_report

        assert_empty report
        assert_empty report.updatable_gems
        assert_empty report.withheld_gems
      end
    end
  end
end
