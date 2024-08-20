# frozen_string_literal: true

require "test_helper"
require "open3"
require "tmpdir"

module BundleUpdateInteractive
  class CLIIntegrationIest < Minitest::Test
    def test_updates_lock_file_based_on_selected_gem_while_honoring_gemfile_requirement
      out, _gemfile, lockfile = run_bundle_update_interactive(
        fixture: "integration",
        argv: [],
        key_presses: "j \n"
      )

      assert_includes out, "Color legend:"

      assert_includes out, "3 gems can be updated."
      assert_includes out, "‣ ⬡ bigdecimal  3.1.7   →"
      assert_includes out, "  ⬡ minitest    5.0.0   →  5.0.8"
      assert_includes out, "  ⬡ rake        12.3.3  →"

      assert_includes out, "‣ ⬢ minitest    5.0.0   →  5.0.8"

      assert_includes out, "Updating the following gems."
      assert_includes out, "minitest  5.0.0  →  5.0.8  :default"

      assert_includes out, "Bundle updated!"

      assert_includes lockfile, <<~LOCK
        GEM
          remote: https://rubygems.org/
          specs:
            bigdecimal (3.1.7)
            minitest (5.0.8)
      LOCK
      assert_includes lockfile, <<~LOCK
        DEPENDENCIES
          bigdecimal
          minitest (~> 5.0.0)
      LOCK
    end

    private

    def run_bundle_update_interactive(fixture:, argv:, key_presses: "\n")
      command = [
        { "GEM_HOME" => ENV.fetch("GEM_HOME", nil) },
        Gem.ruby,
        "-I",
        File.expand_path("../../lib", __dir__),
        File.expand_path("../../exe/bundler-update-interactive", __dir__),
        *argv
      ]
      within_fixture_copy(fixture) do
        Bundler.with_unbundled_env do
          out, err, status = Open3.capture3(*command, stdin_data: key_presses)
          raise "Command failed: #{[out, err].join}" unless status.success?

          [out, File.read("Gemfile"), File.read("Gemfile.lock")]
        end
      end
    end

    def within_fixture_copy(fixture, &block)
      fixture_path = File.join(File.expand_path("../fixtures", __dir__), fixture)
      Dir.mktmpdir do |tmp|
        FileUtils.cp_r(fixture_path, tmp)
        Dir.chdir(File.join(tmp, File.basename(fixture_path)), &block)
      end
    end
  end
end
