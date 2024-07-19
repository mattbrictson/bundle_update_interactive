# frozen_string_literal: true

require "test_helper"

module BundleUpdateInteractive
  class ChangelogLocatorTest < Minitest::Test
    def test_fetches_changelog_uri_from_rubygems
      use_vcr_cassette("test_fetches_changelog_uri_from_rubygems") do
        uri = ChangelogLocator.new.find_changelog_uri(name: "nokogiri", version: "1.16.6")

        assert_equal "https://nokogiri.org/CHANGELOG.html", uri
      end
    end

    def test_falls_back_to_top_level_rubygems_data_when_version_does_not_exist
      use_vcr_cassette("test_falls_back_to_top_level_rubygems_data_when_version_does_not_exist") do
        uri = ChangelogLocator.new.find_changelog_uri(name: "nokogiri", version: "0.123.456")

        assert_equal "https://nokogiri.org/CHANGELOG.html", uri
      end
    end

    def test_discovers_changelog_file_on_github
      use_vcr_cassette("test_discovers_changelog_file_on_github") do
        # This gem doesn't publish changelog_uri metadata, but does have a GitHub URL for its homepage.
        # We should crawl the GitHub repo and discover that it has a CHANGELOG.md file.
        uri = ChangelogLocator.new.find_changelog_uri(name: "ransack", version: "4.2.0")

        assert_equal "https://github.com/activerecord-hackery/ransack/blob/main/CHANGELOG.md", uri
      end
    end

    def test_discovers_changelog_file_on_github_after_following_redirect
      use_vcr_cassette("test_discovers_changelog_file_on_github_after_following_redirect") do
        # This gem doesn't publish changelog_uri metadata, but does have a GitHub URL for its homepage.
        # However the URL in the metadata in this case still points to seattlerb/minitest, when the
        # repo now lives at minitest/minitest. We should follow the redirect to get the correct URL.
        uri = ChangelogLocator.new.find_changelog_uri(name: "minitest", version: "5.16.0")

        assert_equal "https://github.com/minitest/minitest/blob/master/History.rdoc", uri
      end
    end

    def test_discovers_github_releases_url
      use_vcr_cassette("test_discovers_github_releases_url") do
        # This gem doesn't publish changelog_uri metadata, but does have a GitHub URL for its homepage.
        # The repo doesn't have a CHANGELOG.md file, so we should fall back to GitHub Releases.
        uri = ChangelogLocator.new.find_changelog_uri(name: "web-console", version: "4.2.1")

        assert_equal "https://github.com/rails/web-console/releases", uri
      end
    end

    def test_returns_nil_when_changelog_cannot_be_discovered
      use_vcr_cassette("test_returns_nil_when_changelog_cannot_be_discovered") do
        # This gem doesn't publish changelog_uri metadata, and isn't hosted on GitHub,
        # so we don't have a way to discover its changelog.
        uri = ChangelogLocator.new.find_changelog_uri(name: "atlassian-jwt", version: "0.2.1")

        assert_nil uri
      end
    end
  end
end
