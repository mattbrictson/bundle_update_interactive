# frozen_string_literal: true

module BundleUpdateInteractive
  class Updater
    def initialize(groups: [], only_explicit: false)
      @only_explicit = only_explicit
      @gemfile = Gemfile.parse
      @current_lockfile = Lockfile.parse
      @candidate_gems = current_lockfile.gems_exclusively_installed_by(gemfile: gemfile, groups: groups) if groups.any?
    end

    def generate_report
      updatable_gems = find_updatable_gems
      withheld_gems = find_withheld_gems(exclude: updatable_gems.keys)

      Report.new(current_lockfile: current_lockfile, updatable_gems: updatable_gems, withheld_gems: withheld_gems)
    end

    def apply_updates(*gem_names)
      expanded_names = expand_gems_with_exact_dependencies(*gem_names)
      BundlerCommands.update_gems_conservatively(*expanded_names)

      # Return the gems that were actually updated based on observed changes to the lock file
      updated_gems = build_outdated_gems(File.read("Gemfile.lock"))
      @current_lockfile = Lockfile.parse
      updated_gems
    end

    # Overridden by Latest::Updater subclass
    def modified_gemfile?
      false
    end

    private

    attr_reader :gemfile, :current_lockfile, :candidate_gems, :only_explicit

    def find_updatable_gems
      return {} if candidate_gems && candidate_gems.empty?

      updatable = build_outdated_gems(BundlerCommands.read_updated_lockfile(*Array(candidate_gems)))
      updatable = updatable.slice(*gemfile.gem_names) if only_explicit
      updatable
    end

    def build_outdated_gems(lockfile_contents)
      updated_lockfile = Lockfile.parse(lockfile_contents)
      current_lockfile.entries.each_with_object({}) do |current_lockfile_entry, hash|
        name = current_lockfile_entry.name
        updated_lockfile_entry = updated_lockfile && updated_lockfile[name]
        next unless current_lockfile_entry.older_than?(updated_lockfile_entry)
        next if current_lockfile_entry.exact_requirement?

        hash[name] = build_outdated_gem(name, updated_lockfile_entry.version, updated_lockfile_entry.git_version)
      end
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

    def expand_gems_with_exact_dependencies(*gem_names)
      gem_names.flatten!
      gem_names.flat_map { |name| [name, *current_lockfile[name].exact_dependencies] }.uniq
    end
  end
end
