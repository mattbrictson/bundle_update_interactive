# frozen_string_literal: true

require "test_helper"

module BundleUpdateInteractive
  class ChangelogLocatorTest < Minitest::Test
    def test_fetches_changelog_uri_from_rubygems
      VCR.use_cassette("changelog_requests") do
        uri = ChangelogLocator.new.find_changelog_uri(name: "nokogiri", version: "1.16.6")

        assert_equal "https://nokogiri.org/CHANGELOG.html", uri
      end
    end

    def test_falls_back_to_top_level_rubygems_data_when_version_does_not_exist
      VCR.use_cassette("changelog_requests") do
        uri = ChangelogLocator.new.find_changelog_uri(name: "nokogiri", version: "0.123.456")

        assert_equal "https://nokogiri.org/CHANGELOG.html", uri
      end
    end

    def test_discovers_changelog_file_on_github
      VCR.use_cassette("changelog_requests") do
        # This gem doesn't publish changelog_uri metadata, but does have a GitHub URL for its homepage.
        # We should crawl the GitHub repo and discover that it has a CHANGELOG.md file.
        uri = ChangelogLocator.new.find_changelog_uri(name: "ransack", version: "4.2.0")

        assert_equal "https://github.com/activerecord-hackery/ransack/blob/main/CHANGELOG.md", uri
      end
    end

    def test_discovers_changelog_file_on_github_after_following_redirect
      VCR.use_cassette("changelog_requests") do
        # This gem doesn't publish changelog_uri metadata, but does have a GitHub URL for its homepage.
        # However the URL in the metadata in this case still points to seattlerb/minitest, when the
        # repo now lives at minitest/minitest. We should follow the redirect to get the correct URL.
        uri = ChangelogLocator.new.find_changelog_uri(name: "minitest", version: "5.16.0")

        assert_equal "https://github.com/minitest/minitest/blob/master/History.rdoc", uri
      end
    end

    def test_discovers_github_releases_url
      VCR.use_cassette("changelog_requests") do
        # This gem doesn't publish changelog_uri metadata, but does have a GitHub URL for its homepage.
        # The repo doesn't have a CHANGELOG.md file, so we should fall back to GitHub Releases.
        uri = ChangelogLocator.new.find_changelog_uri(name: "web-console", version: "4.2.1")

        assert_equal "https://github.com/rails/web-console/releases", uri
      end
    end

    def test_returns_nil_when_changelog_cannot_be_discovered
      VCR.use_cassette("changelog_requests") do
        # This gem doesn't publish changelog_uri metadata, and isn't hosted on GitHub,
        # so we don't have a way to discover its changelog.
        uri = ChangelogLocator.new.find_changelog_uri(name: "atlassian-jwt", version: "0.2.1")

        assert_nil uri
      end
    end

    def test_returns_nil_when_project_is_on_github_but_is_not_using_releases
      VCR.use_cassette("changelog_requests") do
        # This gem doesn't publish changelog_uri metadata, it *is* on GitHub, but there is no
        # CHANGELOG, etc. file, and the GitHub Releases page doesn't seem to have any data,
        # so we don't have a way to discover its changelog.
        uri = ChangelogLocator.new.find_changelog_uri(name: "parallel", version: "1.26.3")

        assert_nil uri
      end
    end
  end
end
