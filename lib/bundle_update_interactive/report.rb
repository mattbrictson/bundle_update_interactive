# frozen_string_literal: true

require "bundler"
require "set"

module BundleUpdateInteractive
  class Report
    attr_reader :withheld_gems, :updatable_gems

    def initialize(current_lockfile:, withheld_gems:, updatable_gems:)
      @current_lockfile = current_lockfile
      @withheld_gems = withheld_gems.freeze
      @updatable_gems = updatable_gems.freeze
    end

    def empty?
      withheld_gems.empty? && updatable_gems.empty?
    end

    def all_gems
      @all_gems ||= withheld_gems.merge(updatable_gems)
    end

    def scan_for_vulnerabilities! # rubocop:disable Metrics/AbcSize
      return false if all_gems.empty?
      return false unless try_load_bundler_audit

      Bundler::Audit::Database.update!(quiet: true)
      audit_report = Bundler::Audit::Scanner.new.report
      vulnerable_gem_names = Set.new(audit_report.vulnerable_gems.map(&:name))

      all_gems.each do |name, gem|
        exact_deps = current_lockfile && current_lockfile[name].exact_dependencies
        gem.vulnerable = (vulnerable_gem_names & [name, *Array(exact_deps)]).any?
      end
      true
    end

    private

    attr_reader :current_lockfile

    # TODO: Remove this workaround once Bundler 4 compatible version of bundler-audit is released
    def try_load_bundler_audit
      require "bundler/audit"
      require "bundler/audit/scanner"
      true
    rescue LoadError
      puts "Failed to load bundler-audit. Skipping vulnerabilities scan."
      false
    end
  end
end
