# frozen_string_literal: true

module BundleUpdateInteractive
  class Reporter
    def initialize(groups: [])
      @gemfile = Gemfile.parse
      @current_lockfile = Lockfile.parse
      @candidate_gems = current_lockfile.gems_exclusively_installed_by(gemfile: gemfile, groups: groups) if groups.any?
    end

    def generate_report
      updatable_gems = find_updatable_gems
      withheld_gems = find_withheld_gems(exclude: updatable_gems.keys)

      Report.new(current_lockfile: current_lockfile, updatable_gems: updatable_gems, withheld_gems: withheld_gems)
    end

    private

    attr_reader :gemfile, :current_lockfile, :candidate_gems

    def find_updatable_gems
      return {} if candidate_gems && candidate_gems.empty?

      updated_lockfile = Lockfile.parse(BundlerCommands.read_updated_lockfile(*Array(candidate_gems)))
      current_lockfile.entries.each_with_object({}) do |current_lockfile_entry, hash|
        name = current_lockfile_entry.name
        updated_lockfile_entry = updated_lockfile && updated_lockfile[name]
        next unless current_lockfile_entry.older_than?(updated_lockfile_entry)
        next if current_lockfile_entry.exact_requirement?

        hash[name] = build_outdated_gem(name, updated_lockfile_entry.version, updated_lockfile_entry.git_version)
      end
    end

    def build_outdated_gem(name, updated_version, updated_git_version)
      current_lockfile_entry = current_lockfile[name]

      OutdatedGem.new(
        name: name,
        gemfile_groups: gemfile[name]&.groups,
        gemfile_requirement: gemfile[name]&.requirement&.to_s,
        rubygems_source: current_lockfile_entry.rubygems_source?,
        git_source_uri: current_lockfile_entry.git_source_uri&.to_s,
        current_version: current_lockfile_entry.version.to_s,
        current_git_version: current_lockfile_entry.git_version&.strip,
        updated_version: updated_version.to_s,
        updated_git_version: updated_git_version&.strip
      )
    end

    def find_withheld_gems(exclude: [])
      possibly_withheld = gemfile.dependencies.filter_map do |dep|
        dep.name if dep.should_include? && !dep.requirement.none? # rubocop:disable Style/InverseMethods
      end
      possibly_withheld -= exclude
      possibly_withheld &= candidate_gems unless candidate_gems.nil?

      return {} if possibly_withheld.empty?

      BundlerCommands.parse_outdated(*possibly_withheld).to_h do |name, newest|
        [name, build_outdated_gem(name, newest, nil)]
      end
    end
  end
end
