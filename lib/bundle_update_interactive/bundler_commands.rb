# frozen_string_literal: true

require "bundler"
require "shellwords"

module BundleUpdateInteractive
  module BundlerCommands
    class << self
      def update_gems_conservatively(*gems)
        system "#{bundle_bin.shellescape} update --conservative #{gems.flatten.map(&:shellescape).join(' ')}"
      end

      def read_updated_lockfile(*gems)
        command = ["#{bundle_bin.shellescape} lock --print"]
        command << "--conservative" if gems.any?
        command << "--update"
        command.push(*gems.flatten.map(&:shellescape))

        `#{command.join(" ")}`.tap { raise "bundle lock command failed" unless Process.last_status.success? }
      end

      def parse_outdated(*gems)
        command = ["#{bundle_bin.shellescape} outdated --parseable", *gems.flatten.map(&:shellescape)]
        output = `#{command.join(" ")}`
        raise "bundle outdated command failed" if output.empty? && !Process.last_status.success?

        output.scan(/^(\S+) \(newest (\S+),/).to_h
      end

      private

      def bundle_bin
        Gem.bin_path("bundler", "bundle", Bundler::VERSION)
      rescue Gem::GemNotFoundException
        "bundle"
      end
    end
  end
end
