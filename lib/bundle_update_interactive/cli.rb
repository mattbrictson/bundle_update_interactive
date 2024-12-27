# frozen_string_literal: true

require "bundler"
require "concurrent/promises"

module BundleUpdateInteractive
  class CLI
    include Concurrent::Promises::FactoryMethods

    def run(argv: ARGV) # rubocop:disable Metrics/AbcSize
      options = Options.parse(argv)
      report, updater = generate_report(options)

      puts_legend_and_withheld_gems(report) unless report.empty?
      puts("No gems to update.").then { return } if report.updatable_gems.empty?

      selected_gems = MultiSelect.prompt_for_gems_to_update(report.updatable_gems)
      puts("No gems to update.").then { return } if selected_gems.empty?

      puts "Updating the following gems."
      puts Table.updatable(selected_gems).render
      puts

      if options.commit?
        GitCommitter.new(updater).apply_updates_as_individual_commits(*selected_gems.keys)
      else
        updater.apply_updates(*selected_gems.keys)
      end

      puts_gemfile_modified_notice if updater.modified_gemfile?
    rescue Exception => e # rubocop:disable Lint/RescueException
      handle_exception(e)
    end

    private

    def puts_gemfile_modified_notice
      puts BundleUpdateInteractive.pastel.yellow("Your Gemfile was changed to accommodate the latest gem versions.")
    end

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
      updater_class = options.latest? ? Latest::Updater : Updater
      updater = updater_class.new(groups: options.exclusively, only_explicit: options.only_explicit?)

      report = updater.generate_report
      populate_vulnerabilities_and_changelogs_concurrently(report) unless report.empty?

      [report, updater]
    end

    def populate_vulnerabilities_and_changelogs_concurrently(report)
      whisper "Checking for security vulnerabilities..."
      scan_promise = future(report, &:scan_for_vulnerabilities!)
      changelog_promises = report.all_gems.map do |_, outdated_gem|
        future(outdated_gem, &:changelog_uri)
      end
      progress "Finding changelogs", changelog_promises, &:value!
      scan_promise.value!
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
