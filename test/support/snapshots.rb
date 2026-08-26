# frozen_string_literal: true

require "minitest/snapshots_plugin"
require "minitest/snapshots/assertion_extensions"
require "minitest/snapshots/test_extensions"

module BundleUpdateInteractive
  class Test
    include Minitest::Snapshots::TestExtensions

    define_method(:assert_matches_snapshot, Minitest::Assertions.instance_method(:assert_matches_snapshot))
  end
end
