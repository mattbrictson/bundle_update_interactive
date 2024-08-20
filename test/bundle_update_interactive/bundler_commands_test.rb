# frozen_string_literal: true

require "test_helper"
require "bundler"

module BundleUpdateInteractive
  class BundlerCommandsTest < Minitest::Test
    def setup
      Gem.stubs(:bin_path).with("bundler", "bundle", Bundler::VERSION).returns("/exe/bundle")
    end

    def test_lock_executes_bundle_lock
      BundlerCommands.expects(:system).with("/exe/bundle lock").returns(true)

      assert BundlerCommands.lock
    end

    def test_lock_raises_if_bundle_lock_fails
      BundlerCommands.expects(:system).with("/exe/bundle lock").returns(false)

      error = assert_raises(RuntimeError) { BundlerCommands.lock }
      assert_match(/bundle lock command failed/i, error.message)
    end

    def test_read_updated_lockfile_runs_bundle_lock_and_captures_output
      expect_backticks("/exe/bundle lock --print --update", captures: "bundler output")
      result = BundlerCommands.read_updated_lockfile

      assert_equal "bundler output", result
    end

    def test_read_updated_lockfile_runs_bundle_lock_with_specified_gems_conservatively
      expect_backticks(
        "/exe/bundle lock --print --conservative --update actionpack railties",
        captures: "bundler output"
      )
      result = BundlerCommands.read_updated_lockfile("actionpack", "railties")

      assert_equal "bundler output", result
    end

    def test_read_updated_lockfile_raises_if_bundler_fails_to_run
      expect_backticks("/exe/bundle lock --print --update", success: false)

      error = assert_raises(RuntimeError) { BundlerCommands.read_updated_lockfile }
      assert_match(/bundle lock command failed/i, error.message)
    end

    def test_parse_outdated_returns_hash_of_gem_name_to_newest_version
      expect_backticks("/exe/bundle outdated --parseable sqlite3 redis-client", captures: <<~STDOUT, success: true)

        redis-client (newest 0.22.2, installed 0.22.1)
        sqlite3 (newest 2.0.3, installed 1.7.3, requested ~> 1.7)
      STDOUT

      result = BundlerCommands.parse_outdated("sqlite3", "redis-client")
      assert_equal(
        {
          "redis-client" => "0.22.2",
          "sqlite3" => "2.0.3"
        },
        result
      )
    end

    def test_parse_outdated_returns_empty_hash_if_nothing_outdated
      expect_backticks("/exe/bundle outdated --parseable", captures: "\n", success: true)

      result = BundlerCommands.parse_outdated
      assert_empty result
    end

    def test_parse_outdated_raises_if_bundle_command_fails_with_no_output
      expect_backticks("/exe/bundle outdated --parseable", captures: "", success: false)

      error = assert_raises(RuntimeError) { BundlerCommands.parse_outdated }
      assert_match(/bundle outdated command failed/i, error.message)
    end

    private

    def expect_backticks(command, captures: "", success: true)
      status = stub(success?: success)
      Process.stubs(:last_status).returns(status)
      BundlerCommands.expects(:`).with(command).returns(captures)
    end
  end
end
