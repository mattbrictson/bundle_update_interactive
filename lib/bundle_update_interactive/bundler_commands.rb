# frozen_string_literal: true

require "bundler"
require "shellwords"

module BundleUpdateInteractive
  module BundlerCommands
    class << self
      def update_gems_conservatively(*gems, level: nil)
        command = ["#{bundle_bin.shellescape} update"]
        command << "--minor" if level == :minor
        command << "--patch" if level == :patch
        command.push("--conservative #{gems.flatten.map(&:shellescape).join(' ')}")
        system command.join(" ")
      end

      def read_updated_lockfile(*gems, level: nil)
        command = ["#{bundle_bin.shellescape} lock --print"]
        command << "--conservative" if gems.any?
        command << "--minor" if level == :minor
        command << "--patch" if level == :patch
        command << "--update"
        command.push(*gems.flatten.map(&:shellescape))

        `#{command.join(" ")}`.tap { raise "bundle lock command failed" unless Process.last_status.success? }
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
