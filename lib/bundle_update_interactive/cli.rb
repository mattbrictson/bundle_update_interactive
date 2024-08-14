# frozen_string_literal: true

require "bundler"

module BundleUpdateInteractive
  class CLI
    autoload :MultiSelect, "bundle_update_interactive/cli/multi_select"
    autoload :Options, "bundle_update_interactive/cli/options"
    autoload :Row, "bundle_update_interactive/cli/row"
    autoload :Table, "bundle_update_interactive/cli/table"

    def run(argv: ARGV) # rubocop:disable Metrics/AbcSize
      options = Options.parse(argv)
      report = generate_report(options)

      puts_legend_and_withheld_gems(report) unless report.empty?
      puts("No gems to update.").then { return } if report.updatable_gems.empty?

      selected_gems = MultiSelect.prompt_for_gems_to_update(report.updatable_gems)
      puts("No gems to update.").then { return } if selected_gems.empty?

      puts "Updating the following gems."
      puts Table.updatable(selected_gems).render
      puts
      report.bundle_update!(*selected_gems.keys)
    rescue Exception => e # rubocop:disable Lint/RescueException
      handle_exception(e)
    end

    private

    def puts_legend_and_withheld_gems(report)
      puts
      puts legend
      puts
      return if report.withheld_gems.empty?

      puts "The following gems are being held back and cannot be updated."
      puts Table.withheld(report.withheld_gems).render
      puts
    end

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

    def generate_report(options)
      whisper "Resolving latest gem versions..."
      report = Reporter.new(groups: options.exclusively).generate_report
      return report if report.empty?

      whisper "Checking for security vulnerabilities..."
      report.scan_for_vulnerabilities!

      progress "Finding changelogs", report.all_gems.values, &:changelog_uri
      report
    end

    def whisper(message)
      $stderr.puts(message)
    end

    def progress(message, items, &block)
      $stderr.print(message)
      items.each_slice([1, items.length / 12].max) do |slice|
        slice.each(&block)
        $stderr.print(".")
      end
      $stderr.print("\n")
    end

    def handle_exception(error)
      case error
      when Errno::EPIPE
        # Ignore
      when BundleUpdateInteractive::Error, OptionParser::ParseError, Interrupt, Bundler::Dsl::DSLError
        $stderr.puts BundleUpdateInteractive.pastel.red(error.message)
        exit false
      else
        raise
      end
    end
  end
end
