# frozen_string_literal: true

require "delegate"
require "shellwords"

module BundleUpdateInteractive
  class GitCommittingUpdater < SimpleDelegator
    def apply_updates(*gem_names)
      gem_names.each do |name|
        super(name)
        commit_message = "Update #{name} gem"
        system "git add Gemfile Gemfile.lock"
        system "git commit -m #{commit_message.shellescape}"
      end
    end
  end
end
