# frozen_string_literal: true

require "test_helper"

module BundleUpdateInteractive
  class ChangelogLocatorTest < Minitest::Test
    def test_discovers_changelog_file_on_github
      use_vcr_cassette("test_discovers_changelog_file_on_github") do
        # This gem doesn't publish changelog_uri metadata, but does have a GitHub URL for its homepage.
        # We should crawl the GitHub repo and discover that it has a CHANGELOG.md file.
        uri = ChangelogLocator.new.find_changelog_uri(name: "ransack", version: "4.2.0")

        assert_equal "https://github.com/activerecord-hackery/ransack/blob/main/CHANGELOG.md", uri
      end
    end
  end
end
