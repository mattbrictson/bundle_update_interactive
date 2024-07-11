# frozen_string_literal: true

require "faraday"
require "json"

GITHUB_PATTERN = %r{^(?:https?://)?github\.com/([^/]+/[^/]+)(?:\.git)?/?}.freeze
URI_KEYS = %w[source_code_uri homepage_uri bug_tracker_uri wiki_uri].freeze
FILE_PATTERN = /(?:changelog|changes|history|news|release)/.freeze
EXT_PATTERN = /(?:md|txt|rdoc)/.freeze

module BundleUpdateInteractive
  class ChangelogLocator
    # TODO: refactor
    def find_changelog_uri(name:, version: nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      if version
        response = Faraday.get("https://rubygems.org/api/v2/rubygems/#{name}/versions/#{version}.json")
        version = nil unless response.success?
      end

      response = Faraday.get("https://rubygems.org/api/v1/gems/#{name}.json") if version.nil?

      return nil unless response.success?

      data = JSON.parse(response.body)

      version ||= data["version"]
      changelog_uri = data["changelog_uri"]
      github_repo = guess_github_repo(data)

      if changelog_uri.nil? && github_repo
        file_list = Faraday.get("https://github.com/#{github_repo}")
        if file_list.status == 301
          github_repo = file_list.headers["Location"][GITHUB_PATTERN, 1]
          file_list = Faraday.get(file_list.headers["Location"])
        end
        match = file_list.body.match(%r{/(#{github_repo}/blob/[^/]+/#{FILE_PATTERN}(?:\.#{EXT_PATTERN})?)"}i)
        changelog_uri = "https://github.com/#{match[1]}" if match
      end

      if changelog_uri.nil? && github_repo
        releases_uri = "https://github.com/#{github_repo}/releases"
        changelog_uri = releases_uri if Faraday.head("#{releases_uri}/tag/v#{version}").success?
      end

      changelog_uri
    end

    private

    def guess_github_repo(data)
      data.values_at(*URI_KEYS).each do |uri|
        return Regexp.last_match(1) if uri&.match(GITHUB_PATTERN)
      end
      nil
    end
  end
end
