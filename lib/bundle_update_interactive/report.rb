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
      outdated_names = current_lockfile.entries.each_with_object([]) do |current_entry, arr|
        updated_entry = updated_lockfile[current_entry.name]
        arr << current_entry.name if current_entry.older_than?(updated_entry)
      end
      @outdated_gems ||= outdated_names.sort.each_with_object({}) do |name, hash|
        hash[name] = OutdatedGem.new(
          current_lockfile_entry: current_lockfile[name],
          updated_lockfile_entry: updated_lockfile[name],
          gemfile_groups: gemfile[name]&.groups
        )
      end.freeze
    end

    def [](gem_name)
      outdated_gems[gem_name]
    end

    def updateable_gems
      outdated_gems.reject { |_, gem| gem.current_lockfile_entry.exact_dependency? }
    end

    def expand_gems_with_exact_dependencies(*gem_names)
      gem_names.flatten!
      gem_names.flat_map { [_1, *outdated_gems[_1].current_lockfile_entry.exact_dependencies] }.uniq
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
  end
end
