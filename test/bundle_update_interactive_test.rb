# frozen_string_literal: true

class BundleUpdateInteractiveTest < BundleUpdateInteractive::Test
  def test_that_it_has_a_version_number
    refute_nil ::BundleUpdateInteractive::VERSION
  end
end
