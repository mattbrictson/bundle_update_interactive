# frozen_string_literal: true

require "optparse"

module BundleUpdateInteractive
  class CLI::Options
    class << self
      def parse(argv=ARGV)
        options = new
        remaining = build_parser(options).parse!(argv.dup)
        raise Error, "update-interactive does not accept arguments. See --help for available options." if remaining.any?

        options.freeze
      end

      def summary
        build_parser(new).summarize.join.gsub(/^\s+-.*?  /, pastel.yellow('\0'))
      end

      def help # rubocop:disable Metrics/AbcSize
        <<~HELP
          Provides an easy way to update gems to their latest versions.

          #{pastel.bold.underline('USAGE')}
            #{pastel.green('bundle update-interactive')} #{pastel.yellow('[options]')}
            #{pastel.green('bundle ui')} #{pastel.yellow('[options]')}

          #{pastel.bold.underline('OPTIONS')}
          #{summary}
          #{pastel.bold.underline('DESCRIPTION')}
            Displays the list of gems that would be updated by `bundle update`, allowing you
            to navigate them by keyboard and pick which ones to update. A changelog URL,
            when available, is displayed alongside each update. Gems with known security
            vulnerabilities are also highlighted.

            Your Gemfile.lock will be updated conservatively based on the gems you select.
            Transitive dependencies are not affected.

            More information: #{pastel.blue('https://github.com/mattbrictson/bundle_update_interactive')}

          #{pastel.bold.underline('EXAMPLES')}
            Show all gems that can be updated.
            #{pastel.green('bundle update-interactive')}

            The "ui" command alias can also be used.
            #{pastel.green('bundle ui')}

            Show updates for development and test gems only, leaving production gems untouched.
            #{pastel.green('bundle update-interactive')} #{pastel.yellow('-D')}

        HELP
      end

      private

      def pastel
        BundleUpdateInteractive.pastel
      end

      def build_parser(options) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        OptionParser.new do |parser|
          parser.summary_indent = "  "
          parser.summary_width = 24
          parser.on(
            "--exclusively=GROUP",
            "Update gems exclusively belonging to the specified Gemfile GROUP(s)"
          ) do |value|
            options.exclusively = value.split(",").map(&:strip).reject(&:empty?).map(&:to_sym)
          end
          parser.on("-D", "Shorthand for --exclusively=development,test") do
            options.exclusively = %i[development test]
          end
          parser.on("-v", "--version", "Display version") do
            require "bundler"
            puts "bundle_update_interactive/#{VERSION} bundler/#{Bundler::VERSION} #{RUBY_DESCRIPTION}"
            exit
          end
          parser.on("-h", "--help", "Show this help") do
            puts help
            exit
          end
        end
      end
    end

    attr_accessor :exclusively

    def initialize
      @exclusively = []
    end
  end
end
