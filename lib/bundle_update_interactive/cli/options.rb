# frozen_string_literal: true

require "optparse"

module BundleUpdateInteractive
  class CLI::Options
    def self.parse(argv=ARGV)
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
      end.parse!(argv.dup)
    end
  end
end
