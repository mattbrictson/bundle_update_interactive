# frozen_string_literal: true

require "test_helper"

module BundleUpdateInteractive
  class BundlerCommandsTest < Minitest::Test
    def test_read_updated_lockfile_runs_bundle_lock_and_captures_output
      expect_backticks("bundle lock --print --update", captures: "bundler output")
      result = BundlerCommands.read_updated_lockfile

      assert_equal "bundler output", result
    end

    def test_read_updated_lockfile_raises_if_bundler_fails_to_run
      expect_backticks("bundle lock --print --update", success: false)

      error = assert_raises(RuntimeError) { BundlerCommands.read_updated_lockfile }
      assert_match(/bundle lock command failed/i, error.message)
    end

    private

    def expect_backticks(command, captures: "", success: true)
      status = mock(success?: success)
      Process.expects(:last_status).returns(status)
      BundlerCommands.expects(:`).with(command).returns(captures)
    end
  end
end
