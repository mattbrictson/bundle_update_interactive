# frozen_string_literal: true

require "test_helper"

module BundleUpdateInteractive
  module Latest
    class GemRequirementTest < Minitest::Test
      def test_relax_doesnt_affect_greater_than_equal_requirements
        assert_equal(">= 1.0.1", parse(">= 1.0.1").relax.to_s)
      end

      def test_relax_doesnt_affect_not_equal_requirements
        assert_equal("!= 5.2.0", parse("!= 5.2.0").relax.to_s)
      end

      def test_relax_doesnt_affect_greater_than_requirements
        assert_equal("> 1.0.1", parse("> 1.0.1").relax.to_s)
      end

      def test_relax_changes_approximate_requirements_to_greater_than_equal
        assert_equal(">= 5", parse("~> 5").relax.to_s)
        assert_equal(">= 5.2", parse("~> 5.2").relax.to_s)
        assert_equal(">= 5.2.0", parse("~> 5.2.0").relax.to_s)
      end

      def test_relax_changes_exact_requirements_to_greater_than_equal
        assert_equal(">= 0.89.0", parse("0.89.0").relax.to_s)
      end

      def test_relax_changes_less_than_requirements_to_greater_than_equal_zero
        assert_equal(">= 0", parse("< 1.9.5").relax.to_s)
      end

      def test_relax_changes_less_than_equal_requirements_to_greater_than_equal_zero
        assert_equal(">= 0", parse("<= 1.9.5").relax.to_s)
      end

      def test_shift_doesnt_affect_greater_than_equal_requirements
        assert_equal(">= 1.0.1", parse(">= 1.0.1").shift("2.3.5").to_s)
      end

      def test_shift_doesnt_affect_not_equal_requirements
        assert_equal("!= 5.2.0", parse("!= 5.2.0").shift("6.1.2").to_s)
      end

      def test_shift_doesnt_affect_greater_than_requirements
        assert_equal("> 1.0.1", parse("> 1.0.1").shift("2.3.5").to_s)
      end

      def test_shift_doesnt_affect_approximate_requirements_if_new_version_is_compatible
        assert_equal("~> 5.2.0", parse("~> 5.2.0").shift("5.2.6").to_s)
        assert_equal("~> 5.2", parse("~> 5.2").shift("5.4.9").to_s)
      end

      def test_shift_changes_exact_spec_to_new_version
        assert_equal("0.90.0", parse("0.89.0").shift("0.90.0").to_s)
      end

      def test_shift_changes_approximate_requirements_to_accomodate_new_version
        assert_equal("~> 6", parse("~> 5").shift("6.1.2").to_s)
        assert_equal("~> 6.1", parse("~> 5.2").shift("6.1.2").to_s)
        assert_equal("~> 6.1.2", parse("~> 5.2.0").shift("6.1.2").to_s)
      end

      def test_shift_changes_less_than_requirements_to_less_than_equal
        assert_equal("<= 2.1.4", parse("< 1.9.5").shift("2.1.4").to_s)
      end

      def test_shift_changes_less_than_equal_requirements_to_accomodate_new_veresion
        assert_equal("<= 2.1.4", parse("<= 1.9.5").shift("2.1.4").to_s)
      end

      private

      def parse(req)
        GemRequirement.parse(req)
      end
    end
  end
end
