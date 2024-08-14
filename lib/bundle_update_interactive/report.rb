# frozen_string_literal: true

require "bundler"
require "bundler/audit"
require "bundler/audit/scanner"
require "set"

module BundleUpdateInteractive
  class Report
    attr_reader :updatable_gems

    def initialize(current_lockfile:, updatable_gems:)
      @current_lockfile = current_lockfile
      @updatable_gems = updatable_gems.freeze
    end

    def empty?
      updatable_gems.empty?
    end

    def expand_gems_with_exact_dependencies(*gem_names)
      gem_names.flatten!
      gem_names.flat_map { |name| [name, *current_lockfile[name].exact_dependencies] }.uniq
    end

    def scan_for_vulnerabilities!
      return false if empty?

      Bundler::Audit::Database.update!(quiet: true)
      audit_report = Bundler::Audit::Scanner.new.report
      vulnerable_gem_names = Set.new(audit_report.vulnerable_gems.map(&:name))

      updatable_gems.each do |name, gem|
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
