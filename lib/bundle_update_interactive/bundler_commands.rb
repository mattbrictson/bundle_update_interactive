# frozen_string_literal: true

require "shellwords"

module BundleUpdateInteractive
  module BundlerCommands
    class << self
      def update_gems_conservatively(*gems)
        system "bundle update --conservative #{gems.flatten.map(&:shellescape).join(' ')}"
      end

      def read_updated_lockfile
        `bundle lock --print --update`.tap do
          raise "bundle lock command failed" unless Process.last_status.success?
        end
      end
    end
  end
end
