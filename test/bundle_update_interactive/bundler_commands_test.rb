# frozen_string_literal: true

require "test_helper"
require "bundler"

module BundleUpdateInteractive
  class BundlerCommandsTest < Minitest::Test
    def setup
      Gem.stubs(:bin_path).with("bundler", "bundle", Bundler::VERSION).returns("/exe/bundle")
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

    def test_read_updated_lockfile_runs_bundle_lock_with_patch_option
      expect_backticks("/exe/bundle lock --print --patch --update", captures: "bundler output")
      result = BundlerCommands.read_updated_lockfile(level: :patch)

      assert_equal "bundler output", result
    end

    def test_read_updated_lockfile_runs_bundle_lock_with_minor_option
      expect_backticks("/exe/bundle lock --print --minor --update", captures: "bundler output")
      result = BundlerCommands.read_updated_lockfile(level: :minor)

      assert_equal "bundler output", result
    end

    private

    def expect_backticks(command, captures: "", success: true)
      status = mock(success?: success)
      Process.expects(:last_status).returns(status)
      BundlerCommands.expects(:`).with(command).returns(captures)
    end
  end
end
