# frozen_string_literal: true

require "test_helper"

module BundleUpdateInteractive
  class CLI
    class OptionsTest < Minitest::Test
      def test_prints_help_and_exits_when_given_dash_h
        stdout, _stderr, status = capture_io_and_exit_status do
          Options.parse(%w[-h])
        end

        assert_match(/usage/i, stdout)
        assert_equal(0, status)
      end

      def test_prints_help_and_exits_when_given_dash_dash_help
        stdout, _stderr, status = capture_io_and_exit_status do
          Options.parse(%w[--help])
        end

        assert_match(/usage/i, stdout)
        assert_equal(0, status)
      end

      def test_prints_version_and_exits_when_given_dash_v
        stdout, _stderr, status = capture_io_and_exit_status do
          Options.parse(%w[-v])
        end

        assert_match(%r{^bundle_update_interactive/#{Regexp.quote(VERSION)}}, stdout)
        assert_equal(0, status)
      end

      def test_prints_version_and_exits_when_given_dash_dash_version
        stdout, _stderr, status = capture_io_and_exit_status do
          Options.parse(%w[-v])
        end

        assert_match(%r{^bundle_update_interactive/#{Regexp.quote(VERSION)}}, stdout)
        assert_equal(0, status)
      end

      def test_defaults
        options = Options.parse([])

        assert_empty options.exclusively
        refute_predicate options, :latest?
        refute_predicate options, :commit?
        refute_predicate options, :only_explicit?
      end

      def test_allows_exclusive_groups_to_be_specified_as_comma_separated
        options = Options.parse(%w[--exclusively=development,test])
        assert_equal %i[development test], options.exclusively
      end

      def test_dash_capital_d_is_a_shortcut_for_exclusively_development_test
        options = Options.parse(%w[-D])
        assert_equal %i[development test], options.exclusively
      end

      def test_commit_can_be_enabled
        options = Options.parse(["--commit"])

        assert_predicate options, :commit?
      end

      def test_latest_can_be_enabled
        options = Options.parse(["--latest"])

        assert_predicate options, :latest?
      end

      def test_only_explicit_can_be_enabled
        options = Options.parse(["--only_explicit"])

        assert_predicate options, :only_explicit?
      end

      def test_raises_exception_when_given_a_positional_argment
        error = assert_raises(BundleUpdateInteractive::Error) do
          Options.parse(%w[hello])
        end

        assert_match(/update-interactive does not accept arguments/i, error.message)
      end

      def test_raises_exception_when_given_an_unrecognized_option
        error = assert_raises(OptionParser::ParseError) do
          Options.parse(%w[--fast])
        end

        assert_match(/invalid option/i, error.message)
      end

      def test_does_not_modify_argv
        argv = %w[--version]
        capture_io_and_exit_status { Options.parse(argv) }

        assert_equal %w[--version], argv
      end

      def test_parse_returns_an_instance_of_cli_options
        options = Options.parse([])

        assert_instance_of Options, options
      end
    end
  end
end
