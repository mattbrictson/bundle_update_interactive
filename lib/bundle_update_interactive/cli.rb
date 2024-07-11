# frozen_string_literal: true

require "thor"

module BundleUpdateInteractive
  class CLI < Thor
    autoload :MultiSelect, "bundle_update_interactive/cli/multi_select"
    autoload :Row, "bundle_update_interactive/cli/row"
    autoload :Table, "bundle_update_interactive/cli/table"
    autoload :ThorExt, "bundle_update_interactive/cli/thor_ext"

    extend ThorExt::Start

    default_command :ui
    map %w[-v --version] => "version"

    desc "version", "Display bundle_update_interactive version", hide: true
    def version
      say "bundle_update_interactive/#{VERSION} #{RUBY_DESCRIPTION}"
    end

    desc "ui", "Update Gemfile.lock interactively", hide: true
    def ui # rubocop:disable Metrics/AbcSize
      report = generate_report
      say("No gems to update.") && return if report.updateable_gems.empty?

      say
      say legend
      say
      selected_gems = MultiSelect.prompt_for_gems_to_update(report.updateable_gems)
      say("No gems to update.") && return if selected_gems.empty?

      say "\nUpdating the following gems."
      say
      say Table.new(selected_gems).render
      say
      report.bundle_update!(*selected_gems.keys)
    end

    private

    def legend
      pastel = BundleUpdateInteractive.pastel
      <<~LEGEND
        Color legend:
        #{pastel.white.on_red('<inverse>')} Known security vulnerability
        #{pastel.red('<red>')}     Major update; likely to have breaking changes, high risk
        #{pastel.yellow('<yellow>')}  Minor update; changes and additions, moderate risk
        #{pastel.green('<green>')}   Patch update; bug fixes, low risk
        #{pastel.cyan('<cyan>')}    Possibly unreleased git commits; unknown risk
      LEGEND
    end

    def generate_report
      whisper "Resolving latest gem versions..."
      report = Report.generate
      updateable_gems = report.updateable_gems
      return report if updateable_gems.empty?

      whisper "Checking for security vulnerabilities..."
      report.scan_for_vulnerabilities!

      progress "Finding changelogs", updateable_gems.values, &:changelog_uri
      report
    end

    def whisper(message)
      $stderr.puts(message) # rubocop:disable Style/StderrPuts
    end

    def progress(message, items, &block)
      $stderr.print(message)
      items.each_slice([1, items.length / 12].max) do |slice|
        slice.each(&block)
        $stderr.print(".")
      end
      $stderr.print("\n")
    end
  end
end
