# frozen_string_literal: true

require "test_helper"
require "bundler"

module BundleUpdateInteractive
  module Latest
    class UpdaterTest < Minitest::Test
      def test_generate_report_doesnt_run_bundle_outdated_and_always_returns_no_withheld_gems
        Dir.chdir(File.expand_path("../../fixtures", __dir__)) do
          updated_lockfile = File.read("Gemfile.lock.updated")
          BundlerCommands.expects(:read_updated_lockfile).with.returns(updated_lockfile)
          BundlerCommands.expects(:parse_outdated).never

          report = Updater.new.generate_report

          assert_empty report.withheld_gems
        end
      end

      def test_generate_report_relaxes_gemfile_and_restores_it
        Dir.chdir(File.expand_path("../../fixtures", __dir__)) do
          updatable_gems = { "sqlite3" => build(:outdated_gem, name: "sqlite3") }
          editor = GemfileEditor.new
          editor.expects(:with_relaxed_gemfile).returns(updatable_gems)

          report = Updater.new(editor: editor).generate_report

          assert_equal updatable_gems, report.updatable_gems
        end
      end

      def test_apply_updates_modifies_gemfile_and_runs_bundle_lock
        editor = GemfileEditor.new
        editor.expects(:with_relaxed_gemfile)
        editor.expects(:shift_gemfile).returns(true)
        BundlerCommands.expects(:lock)

        updater = Updater.new(editor: editor)
        updater.apply_updates("rails")

        assert_predicate updater, :modified_gemfile?
      end

      def test_apply_updates_doesnt_modify_gemfile_if_lockfile_is_unchanged
        editor = GemfileEditor.new
        editor.expects(:with_relaxed_gemfile)
        editor.expects(:shift_gemfile).returns(false)
        BundlerCommands.expects(:lock)

        updater = Updater.new(editor: editor)
        updater.apply_updates("rails")

        refute_predicate updater, :modified_gemfile?
      end
    end
  end
end
