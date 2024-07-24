# frozen_string_literal: true

require "bundler"
require "bundler/audit"
require "bundler/audit/scanner"
require "set"

module BundleUpdateInteractive
  class Report
    class << self
      def generate
        gemfile = Gemfile.parse
        current_lockfile = Lockfile.parse
        updated_lockfile = Lockfile.parse(BundlerCommands.read_updated_lockfile)

        new(gemfile: gemfile, current_lockfile: current_lockfile, updated_lockfile: updated_lockfile)
      end
    end

    attr_reader :outdated_gems

    def initialize(gemfile:, current_lockfile:, updated_lockfile:)
      @current_lockfile = current_lockfile
      @outdated_gems = current_lockfile.entries.each_with_object({}) do |current_lockfile_entry, hash|
        name = current_lockfile_entry.name
        updated_lockfile_entry = updated_lockfile[name]
        next unless current_lockfile_entry.older_than?(updated_lockfile_entry)

        hash[name] = build_outdated_gem(current_lockfile_entry, updated_lockfile_entry, gemfile[name]&.groups)
      end.freeze
    end

    def [](gem_name)
      outdated_gems[gem_name]
    end

    def updateable_gems
      @updateable_gems ||= outdated_gems.reject do |name, _|
        current_lockfile[name].exact_requirement?
      end.freeze
    end

    def expand_gems_with_exact_dependencies(*gem_names)
      gem_names.flatten!
      gem_names.flat_map { |name| [name, *current_lockfile[name].exact_dependencies] }.uniq
    end

    def scan_for_vulnerabilities!
      return false if outdated_gems.empty?

      Bundler::Audit::Database.update!(quiet: true)
      audit_report = Bundler::Audit::Scanner.new.report
      vulnerable_gem_names = Set.new(audit_report.vulnerable_gems.map(&:name))

      outdated_gems.each do |name, gem|
        gem.vulnerable = (vulnerable_gem_names & [name, *current_lockfile[name].exact_dependencies]).any?
      end
      true
    end

    def bundle_update!(*gem_names)
      expanded_names = expand_gems_with_exact_dependencies(*gem_names)
      BundlerCommands.update_gems_conservatively(*expanded_names)
    end

    private

    attr_reader :current_lockfile

    def build_outdated_gem(current_lockfile_entry, updated_lockfile_entry, gemfile_groups)
      OutdatedGem.new(
        name: current_lockfile_entry.name,
        gemfile_groups: gemfile_groups,
        rubygems_source: updated_lockfile_entry.rubygems_source?,
        git_source_uri: updated_lockfile_entry.git_source_uri&.to_s,
        current_version: current_lockfile_entry.version.to_s,
        current_git_version: current_lockfile_entry.git_version&.strip,
        updated_version: updated_lockfile_entry.version.to_s,
        updated_git_version: updated_lockfile_entry.git_version&.strip
      )
    end
  end
end
