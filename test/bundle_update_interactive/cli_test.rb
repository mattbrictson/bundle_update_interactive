# frozen_string_literal: true

require "test_helper"

module BundleUpdateInteractive
  class CLIIest < Minitest::Test
    def test_shows_help_and_exits
      stdout, stderr, status = capture_io_and_exit_status do
        CLI.new.run(argv: %w[--help])
      end

      assert_match(/usage:/i, stdout)
      assert_empty(stderr)
      assert_equal(0, status)
    end

    def test_prints_error_in_red_to_stderr_and_exits_with_failure_status
      Report.expects(:generate).raises(Error, "something went wrong")

      stdout, stderr, status = capture_io_and_exit_status do
        CLI.new.run(argv: [])
      end

      assert_empty(stdout)
      assert_equal("Resolving latest gem versions...\n\e[31msomething went wrong\e[0m\n", stderr)
      assert_equal(1, status)
    end

    def test_returns_if_no_gems_to_update
      empty_report = mock
      empty_report.expects(:updateable_gems).at_least_once.returns({})
      Report.expects(:generate).returns(empty_report)

      stdout, stderr = capture_io do
        CLI.new.run(argv: [])
      end

      assert_equal("Resolving latest gem versions...\n", stderr)
      assert_equal("No gems to update.\n", stdout)
    end

    def test_shows_interactive_list_of_gems_and_updates_the_selected_ones
      stdout, stderr, status = Dir.chdir(File.expand_path("../fixtures", __dir__)) do
        VCR.use_cassette("changelog_requests") do
          updated_lockfile = File.read("Gemfile.lock.updated")
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

      _menu, selected_gems = stdout.split("Updating the following gems.")
      assert_equal(3, selected_gems.lines.grep(/→/).count)
      assert_match(/addressable/, selected_gems)
      assert_match(/bigdecimal/, selected_gems)
      assert_match(/builder/, selected_gems)
      assert_nil(status)
    end
  end
end
