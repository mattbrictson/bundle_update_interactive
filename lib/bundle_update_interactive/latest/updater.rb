# frozen_string_literal: true

# Extends the default Updater class to allow updating to the latest gem versions.
# Does this by using GemfileEditor to relax the Gemfile requirements before
# `find_updatable_gems` and `apply_updates` are called.
module BundleUpdateInteractive
  module Latest
    class Updater < BundleUpdateInteractive::Updater
      def initialize(editor: GemfileEditor.new, **kwargs)
        super(**kwargs)
        @modified_gemfile = false
        @editor = editor
      end

      def apply_updates(*, **)
        result = editor.with_relaxed_gemfile { super }
        @modified_gemfile = editor.shift_gemfile
        BundlerCommands.lock
        result
      end

      def modified_gemfile?
        @modified_gemfile
      end

      private

      attr_reader :editor

      def find_updatable_gems
        editor.with_relaxed_gemfile { super }
      end

      # Overrides the default Updater implementation.
      # When updating the latest gems, by definition nothing is withheld, so we can skip this.
      def find_withheld_gems(**)
        {}
      end
    end
  end
end
