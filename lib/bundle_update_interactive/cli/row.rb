# frozen_string_literal: true

require "delegate"
require "pastel"

class BundleUpdateInteractive::CLI
  class Row < SimpleDelegator
    SEMVER_COLORS = {
      major: :red,
      minor: :yellow,
      patch: :green
    }.freeze

    def initialize(outdated_gem)
      super
      @pastel = BundleUpdateInteractive.pastel
    end

    def formatted_gem_name
      vulnerable? ? pastel.white.on_red(name) : apply_semver_highlight(name)
    end

    def formatted_current_version
      [current_version.to_s, current_git_version].compact.join(" ")
    end

    def formatted_updated_version
      version = semver_change.format { |part| apply_semver_highlight(part) }
      git_version = apply_semver_highlight(updated_git_version)

      [version, git_version].compact.join(" ")
    end

    def formatted_gemfile_groups
      gemfile_groups&.map(&:inspect)&.join(", ")
    end

    def formatted_gemfile_requirement
      gemfile_requirement.to_s == ">= 0" ? "" : gemfile_requirement.to_s
    end

    def formatted_changelog_uri
      pastel.blue(changelog_uri)
    end

    def apply_semver_highlight(value)
      color = git_version_changed? ? :cyan : SEMVER_COLORS.fetch(semver_change.severity)
      pastel.decorate(value, color)
    end

    private

    attr_reader :pastel
  end
end
