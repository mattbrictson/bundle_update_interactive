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
      Reporter.expects(:new).raises(Error, "something went wrong")

      stdout, stderr, status = capture_io_and_exit_status do
        CLI.new.run(argv: [])
      end

      assert_empty(stdout)
      assert_equal("Resolving latest gem versions...\n\e[31msomething went wrong\e[0m\n", stderr)
      assert_equal(1, status)
    end

    def test_returns_if_no_gems_to_update_and_nothing_withheld
      empty_report = stub(empty?: true, updatable_gems: {}, withheld_gems: {})
      Reporter.expects(:new).returns(mock(generate_report: empty_report))

      stdout, stderr = capture_io do
        CLI.new.run(argv: [])
      end

      assert_equal("Resolving latest gem versions...\n", stderr)
      assert_equal("No gems to update.\n", stdout)
    end

    def test_prints_withheld_gems_and_returns_if_nothing_to_update
      stdout, stderr, status = Dir.chdir(File.expand_path("../fixtures", __dir__)) do
        VCR.use_cassette("changelog_requests") do
          unchanged_lockfile = File.read("Gemfile.lock")
          BundlerCommands.expects(:parse_outdated).returns({ "sqlite3" => "2.0.3" })
          BundlerCommands.expects(:read_updated_lockfile).returns(unchanged_lockfile)
          mock_vulnerable_gems([])

          capture_io_and_exit_status do
            CLI.new.run(argv: [])
          end
        end
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

    def test_shows_withheld_gems_and_interactive_list_of_gems_and_updates_the_selected_ones
      stdout, stderr, status = Dir.chdir(File.expand_path("../fixtures", __dir__)) do
        VCR.use_cassette("changelog_requests") do
          updated_lockfile = File.read("Gemfile.lock.updated")
          BundlerCommands.expects(:parse_outdated).returns({ "sqlite3" => "2.0.3" })
          BundlerCommands.expects(:read_updated_lockfile).returns(updated_lockfile)
          BundlerCommands.expects(:update_gems_conservatively).with("addressable", "bigdecimal", "builder")
          mock_vulnerable_gems([])

          stdin_data = " j j \n" # SPACE,DOWN,SPACE,DOWN,SPACE,ENTER selects first three gems to update
          capture_io_and_exit_status(stdin_data: stdin_data) do
            CLI.new.run(argv: [])
          end
        end
      end

      assert_equal(<<~EXPECTED_STDERR, stderr)
        Resolving latest gem versions...
        Checking for security vulnerabilities...
        Finding changelogs..................
      EXPECTED_STDERR

      menu, selected_gems = stdout.split("Updating the following gems.")

      assert_match(/The following gems are being held back and cannot be updated/, menu)
      assert_match(/sqlite3.*2\.0\.3/, menu)

      assert_equal(3, selected_gems.lines.grep(/→/).count)
      assert_match(/addressable/, selected_gems)
      assert_match(/bigdecimal/, selected_gems)
      assert_match(/builder/, selected_gems)
      assert_nil(status)
    end
  end
end
