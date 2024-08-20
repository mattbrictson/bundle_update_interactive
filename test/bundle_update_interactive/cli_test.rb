# frozen_string_literal: true

require "test_helper"

module BundleUpdateInteractive
  class CLIIest < Minitest::Test
    def test_shows_help_and_exits
      stdout, stderr, status = capture_io_and_exit_status do
        CLI.new.run(argv: %w[--help])
      end

      assert_match(/usage/i, stdout)
      assert_empty(stderr)
      assert_equal(0, status)
    end

    def test_prints_error_in_red_to_stderr_and_exits_with_failure_status
      Updater.expects(:new).raises(Error, "something went wrong")

      stdout, stderr, status = capture_io_and_exit_status do
        CLI.new.run(argv: [])
      end

      assert_empty(stdout)
      assert_equal("Resolving latest gem versions...\n\e[31msomething went wrong\e[0m\n", stderr)
      assert_equal(1, status)
    end

    def test_returns_if_no_gems_to_update_and_nothing_withheld
      stub_report(updatable_gems: {}, withheld_gems: {})

      stdout, stderr = capture_io do
        CLI.new.run(argv: [])
      end

      assert_equal("Resolving latest gem versions...\n", stderr)
      assert_equal("No gems to update.\n", stdout)
    end

    def test_prints_withheld_gems_and_returns_if_nothing_to_update
      report = stub_report(
        updatable_gems: {},
        withheld_gems: {
          "sqlite3" => build(:outdated_gem, name: "sqlite3", updated_version: "2.0.3", changelog_uri: nil)
        }
      )
      report.expects(:scan_for_vulnerabilities!)

      stdout, stderr, status = capture_io_and_exit_status do
        CLI.new.run(argv: [])
      end

      assert_equal(<<~EXPECTED_STDERR, stderr)
        Resolving latest gem versions...
        Checking for security vulnerabilities...
        Finding changelogs.
      EXPECTED_STDERR

      assert_match(/The following gems are being held back and cannot be updated/, stdout)
      assert_match(/sqlite3.*2\.0\.3/, stdout)
      assert_match(/^No gems to update.\n\z/, stdout)
      assert_nil(status)
    end

    def test_uses_correct_grammar_when_only_one_gem_can_be_updated
      report = stub_report(
        updatable_gems: {
          "sqlite3" => build(
            :outdated_gem,
            name: "sqlite3",
            current_version: "1.7.3",
            updated_version: "2.0.3",
            changelog_uri: nil
          )
        }
      )

      report.expects(:scan_for_vulnerabilities!)

      stdout, _stderr, _status = capture_io_and_exit_status(stdin_data: "\n") do
        CLI.new.run(argv: [])
      end

      assert_includes stdout, "1 gem can be updated"
    end

    private

    def stub_report(withheld_gems: {}, updatable_gems: {})
      report = Report.new(
        current_lockfile: nil,
        withheld_gems: withheld_gems,
        updatable_gems: updatable_gems
      )

      updater = Updater.new
      updater.stubs(:generate_report).returns(report)
      Updater.stubs(:new).returns(updater)
      report
    end
  end
end
