# frozen_string_literal: true

require "bundler"
require "bundler/audit"
require "bundler/audit/scanner"

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

    # Gems with a known security vulnerability that can be updated. Major version bumps are
    # excluded unless include_major_updates is true. scan_for_vulnerabilities! must be run first.
    def security_updates(include_major_updates: false)
      updatable_gems.select do |_name, gem|
        gem.vulnerable? && (include_major_updates || !gem.semver_change.major?)
      end
    end

    def scan_for_vulnerabilities!
      return false if all_gems.empty?

      Bundler::Audit::Database.update!(quiet: true)
      audit_report = Bundler::Audit::Scanner.new.report
      advisories_by_gem = collect_advisories(audit_report)

      all_gems.each do |name, gem|
        exact_deps = current_lockfile && current_lockfile[name].exact_dependencies
        gem.advisories = [name, *Array(exact_deps)].flat_map { |n| advisories_by_gem[n] }
        gem.vulnerable = gem.advisories.any?
      end
      true
    end

    private

    attr_reader :current_lockfile

    def collect_advisories(audit_report)
      audit_report.unpatched_gems.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |result, advisories|
        advisory = result.advisory
        url = advisory.url
        url = "https://github.com/advisories/GHSA-#{advisory.ghsa}" if !url.to_s.include?("github.com") && advisory.ghsa

        advisories[result.gem.name] << { title: advisory.title, url: url, criticality: advisory.criticality }
      end
    end
  end
end
