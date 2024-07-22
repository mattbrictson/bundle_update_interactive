# frozen_string_literal: true

require "optparse"

module BundleUpdateInteractive
  class CLI::Options
    class << self
      def parse(argv=ARGV)
        remaining = parser.parse!(argv.dup)
        raise Error, "update-interactive does not accept arguments. See --help for available options." if remaining.any?
      end

      private

      def parser
        OptionParser.new do |parser|
          parser.banner = "Usage: bundle update-interactive"
          parser.on("-v", "--version", "Display bundle_update_interactive version") do
            require "bundler"
            puts "bundle_update_interactive/#{VERSION} bundler/#{Bundler::VERSION} #{RUBY_DESCRIPTION}"
            exit
          end
          parser.on("-h", "--help", "Show this help") do
            puts parser
            exit
          end
        end
      end
    end
  end
end
