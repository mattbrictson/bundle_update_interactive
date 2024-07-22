# frozen_string_literal: true

require "test_helper"

module BundleUpdateInteractive
  class CLI::OptionsTest < Minitest::Test
    def test_prints_help_and_exits_when_given_dash_h
      stdout, status = capturing_stdout_and_exit_status do
        CLI::Options.parse(%w[-h])
      end

      assert_match(/usage:/i, stdout)
      assert_equal(0, status)
    end

    def test_prints_help_and_exits_when_given_dash_dash_help
      stdout, status = capturing_stdout_and_exit_status do
        CLI::Options.parse(%w[--help])
      end

      assert_match(/usage:/i, stdout)
      assert_equal(0, status)
    end

    def test_prints_version_and_exits_when_given_dash_v
      stdout, status = capturing_stdout_and_exit_status do
        CLI::Options.parse(%w[-v])
      end

      assert_match(%r{^bundle_update_interactive/#{Regexp.quote(VERSION)}}, stdout)
      assert_equal(0, status)
    end

    def test_prints_version_and_exits_when_given_dash_dash_version
      stdout, status = capturing_stdout_and_exit_status do
        CLI::Options.parse(%w[-v])
      end

      assert_match(%r{^bundle_update_interactive/#{Regexp.quote(VERSION)}}, stdout)
      assert_equal(0, status)
    end

    def test_raises_exception_when_given_a_positional_argment
      error = assert_raises(BundleUpdateInteractive::Error) do
        CLI::Options.parse(%w[hello])
      end

      assert_match(/update-interactive does not accept arguments/i, error.message)
    end

    def test_raises_exception_when_given_an_unrecognized_option
      error = assert_raises(OptionParser::ParseError) do
        CLI::Options.parse(%w[--fast])
      end

      assert_match(/invalid option/i, error.message)
    end

    def test_does_not_modify_argv
      argv = %w[--version]
      capturing_stdout_and_exit_status { CLI::Options.parse(argv) }

      assert_equal %w[--version], argv
    end

    private

    def capturing_stdout_and_exit_status
      exit_status = nil
      stdout = +""

      out, err = capture_io do
        yield
      rescue SystemExit => e
        exit_status = e.status
      end

      stdout << out
      $stderr << err unless err.empty?

      [stdout, exit_status]
    end
  end
end
