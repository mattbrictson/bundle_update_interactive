# frozen_string_literal: true

require "test_helper"

module BundleUpdateInteractive
  class OutdatedGemTest < Minitest::Test
    def test_changelog_uri_delegates_to_changelog_locator_for_rubygems_source
      changelog_locator = mock
      ChangelogLocator.expects(:new).returns(changelog_locator)
      changelog_locator.expects(:find_changelog_uri).with(name: "rails", version: "7.1.3.4")
        .returns("https://github.com/rails/rails/releases/tag/v7.1.3.4")

      outdated_gem = build(
        :outdated_gem,
        rubygems_source: true,
        name: "rails",
        updated_version: "7.1.3.4"
      )

      assert_equal "https://github.com/rails/rails/releases/tag/v7.1.3.4", outdated_gem.changelog_uri
    end

    def test_changelog_uri_builds_github_comparison_url_if_github_repo
      outdated_gem = build(
        :outdated_gem,
        rubygems_source: false,
        name: "mighty_test",
        git_source_uri: "https://github.com/mattbrictson/mighty_test.git",
        current_git_version: "302ad5c",
        updated_git_version: "e27ab73"
      )

      assert_equal "https://github.com/mattbrictson/mighty_test/compare/302ad5c...e27ab73", outdated_gem.changelog_uri
    end

    def test_changelog_uri_builds_github_comparison_url_if_bitbucket_cloud_repo
      outdated_gem = build(
        :outdated_gem,
        rubygems_source: false,
        name: "atlassian-jwt",
        git_source_uri: "https://bitbucket.org/atlassian/atlassian-jwt-ruby.git",
        current_git_version: "7c06fd5",
        updated_git_version: "e8b7a92"
      )

      assert_equal(
        "https://bitbucket.org/atlassian/atlassian-jwt-ruby/branches/compare/e8b7a92..7c06fd5",
        outdated_gem.changelog_uri
      )
    end

    def test_changelog_uri_falls_back_to_gem_spec_homepage_if_unsupported_git_repo
      Gem::Specification
        .expects(:find_by_name)
        .with("httpx")
        .returns(Gem::Specification.new("httpx") { |spec| spec.homepage = "https://honeyryderchuck.gitlab.io/httpx/" })

      outdated_gem = build(
        :outdated_gem,
        rubygems_source: false,
        name: "httpx",
        git_source_uri: "https://gitlab.com/os85/httpx.git",
        current_git_version: "e250ea5",
        updated_git_version: "7278647"
      )

      assert_equal "https://honeyryderchuck.gitlab.io/httpx/", outdated_gem.changelog_uri
    end
  end
end
