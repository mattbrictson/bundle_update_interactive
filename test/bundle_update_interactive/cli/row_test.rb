# frozen_string_literal: true

require "test_helper"

module BundleUpdateInteractive
  class CLI
    class RowTest < Minitest::Test
      def test_formatted_gem_name_for_vulnerable_gem_is_red_on_white
        outdated_gem = build(:outdated_gem, name: "rails", vulnerable: true)
        row = Row.new(outdated_gem)

        assert_equal "\e[37;41mrails\e[0m", row.formatted_gem_name
      end

      def test_formatted_updated_version_highlights_diff_in_cyan_regardless_of_semver_change
        outdated_gem = build(
          :outdated_gem,
          current_version: "7.0.5",
          updated_version: "7.1.2",
          current_git_version: "a1a1207",
          updated_git_version: "0e5bafe"
        )
        row = Row.new(outdated_gem)

        assert_equal "7.\e[36m1.2\e[0m \e[36m0e5bafe\e[0m", row.formatted_updated_version
      end

      def test_name_and_version_red_if_major_semver_change
        outdated_gem = build(:outdated_gem, name: "rails", current_version: "6.1.2", updated_version: "7.0.3")
        row = Row.new(outdated_gem)

        assert_equal "\e[31mrails\e[0m", row.formatted_gem_name
        assert_equal "\e[31m7.0.3\e[0m", row.formatted_updated_version
      end

      def test_name_and_version_yellow_if_minor_semver_change
        outdated_gem = build(:outdated_gem, name: "rails", current_version: "7.0.3", updated_version: "7.1.0")
        row = Row.new(outdated_gem)

        assert_equal "\e[33mrails\e[0m", row.formatted_gem_name
        assert_equal "7.\e[33m1.0\e[0m", row.formatted_updated_version
      end

      def test_name_and_version_green_if_patch_semver_change
        outdated_gem = build(:outdated_gem, name: "rails", current_version: "7.0.3", updated_version: "7.0.4")
        row = Row.new(outdated_gem)

        assert_equal "\e[32mrails\e[0m", row.formatted_gem_name
        assert_equal "7.0.\e[32m4\e[0m", row.formatted_updated_version
      end

      def test_formatted_gemfile_groups_handles_nil_groups
        outdated_gem = build(:outdated_gem, gemfile_groups: nil)
        row = Row.new(outdated_gem)

        assert_nil row.formatted_gemfile_groups
      end

      def test_formatted_gemfile_groups_returns_comma_separated_symbols
        outdated_gem = build(:outdated_gem, gemfile_groups: %i[development test])
        row = Row.new(outdated_gem)

        assert_equal ":development, :test", row.formatted_gemfile_groups
      end

      def test_formatted_gemfile_requirement_treats_trivial_requirement_as_nil
        outdated_gem = build(:outdated_gem, gemfile_requirement: ">= 0")
        row = Row.new(outdated_gem)

        assert_equal "", row.formatted_gemfile_requirement
      end
    end
  end
end
