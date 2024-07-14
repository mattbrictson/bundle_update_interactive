# frozen_string_literal: true

require "test_helper"

module BundleUpdateInteractive
  class SemverTest < Minitest::Test
    def test_prerelease_is_considered_patch
      change = SemverChange.new("7.2.0.beta2", "7.2.0.beta3")

      assert_equal :patch, change.severity
      assert_predicate change, :patch?

      refute_predicate change, :minor?
      refute_predicate change, :major?
    end

    def test_change_in_fourth_segment_is_considered_patch
      change = SemverChange.new("7.1.3.3", "7.1.3.4")

      assert_equal :patch, change.severity
      assert_predicate change, :patch?

      refute_predicate change, :minor?
      refute_predicate change, :major?
    end

    def test_change_in_first_segment_is_major
      change = SemverChange.new("6.1.7", "7.0.0")

      assert_equal :major, change.severity
      assert_predicate change, :major?

      refute_predicate change, :patch?
      refute_predicate change, :minor?
    end

    def test_change_in_second_segment_is_minor
      change = SemverChange.new("7.0.8", "7.1.0")

      assert_equal :minor, change.severity
      assert_predicate change, :minor?

      refute_predicate change, :patch?
      refute_predicate change, :major?
    end

    def test_change_in_third_segment_is_patch
      change = SemverChange.new("7.1.0", "7.1.1")

      assert_equal :patch, change.severity
      assert_predicate change, :patch?

      refute_predicate change, :minor?
      refute_predicate change, :major?
    end

    def test_format_applies_to_all_segments_starting_with_changed_one
      formatter = ->(str) { "<#{str}>" }

      assert_equal "<2.1.6>", SemverChange.new("1.2.9", "2.1.6").format(&formatter)
      assert_equal "2.<1.6>", SemverChange.new("2.0.9", "2.1.6").format(&formatter)
      assert_equal "2.1.<6>", SemverChange.new("2.1.5", "2.1.6").format(&formatter)
      assert_equal "2.1.6.<1>", SemverChange.new("2.1.6", "2.1.6.1").format(&formatter)
    end

    def test_none_is_true_when_versions_are_identical
      change = SemverChange.new("1.0.3", "1.0.3")

      assert_predicate change, :none?
      refute_predicate change, :any?
    end

    def test_none_is_false_when_versions_are_different
      change = SemverChange.new("1.0.3", "1.0.4")

      refute_predicate change, :none?
      assert_predicate change, :any?
    end
  end
end
