# frozen_string_literal: true

require "test_helper"
require "json"
require "open3"
require "tmpdir"

module BundleUpdateInteractive
  class CLIIntegrationIest < Minitest::Test
    def test_updates_lock_file_based_on_selected_gem_while_honoring_gemfile_requirement
      out, _gemfile, lockfile = within_fixture_copy("integration") do
        run_bundle_update_interactive(argv: [], key_presses: "j \n")
      end

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

    def test_omits_indirect_gems_when_only_explicit_option_is_passed
      out, _gemfile, _lockfile = within_fixture_copy("integration/with_indirect") do
        run_bundle_update_interactive(argv: ["--only-explicit"], key_presses: "\n")
      end

      assert_includes out, "1 gem can be updated."
      assert_includes out, "‣ ⬡ mail"
    end

    def test_updates_lock_file_and_gemfile_to_accommodate_latest_version_when_latest_option_is_specified
      latest_minitest_version = fetch_latest_gem_version_from_rubygems_api("minitest")

      out, gemfile, lockfile = within_fixture_copy("integration") do
        run_bundle_update_interactive(argv: ["--latest"], key_presses: "j \n")
      end

      assert_includes out, "Color legend:"

      assert_includes out, "3 gems can be updated."
      assert_includes out, "‣ ⬡ bigdecimal  3.1.7   →"
      assert_includes out, "  ⬡ minitest    5.0.0   →  #{latest_minitest_version}"
      assert_includes out, "  ⬡ rake        12.3.3  →"

      assert_includes out, "‣ ⬢ minitest    5.0.0   →  #{latest_minitest_version}"

      assert_includes out, "Updating the following gems."
      assert_includes out, "minitest  5.0.0  →  #{latest_minitest_version}  :default"

      assert_includes out, "Bundle updated!"
      assert_includes out, "Your Gemfile was changed"

      assert_includes gemfile, <<~GEMFILE
        gem "minitest", "~> #{latest_minitest_version}"
      GEMFILE

      assert_includes lockfile, <<~LOCK
        GEM
          remote: https://rubygems.org/
          specs:
            bigdecimal (3.1.7)
            minitest (#{latest_minitest_version})
      LOCK
      assert_includes lockfile, <<~LOCK
        DEPENDENCIES
          bigdecimal
          minitest (~> #{latest_minitest_version})
      LOCK
    end

    def test_updates_each_selected_gem_with_a_git_commit
      out, _gemfile, _lockfile = within_fixture_copy("integration") do
        system "git init", out: File::NULL, exception: true
        system "git add .", out: File::NULL, exception: true
        system "git commit -m init", out: File::NULL, exception: true
        run_bundle_update_interactive(argv: ["--commit"], key_presses: " j \n")
      end

      assert_match(/^\[(main|master) \h+\] Update bigdecimal 3\.1\.7 →/, out)
      assert_match(/^\[(main|master) \h+\] Update minitest 5\.0\.0 →/, out)
    end

    private

    def run_bundle_update_interactive(argv:, key_presses: "\n")
      command = [
        { "GEM_HOME" => ENV.fetch("GEM_HOME", nil) },
        Gem.ruby,
        "-I",
        File.expand_path("../../lib", __dir__),
        File.expand_path("../../exe/bundler-update-interactive", __dir__),
        *argv
      ]
      Bundler.with_unbundled_env do
        out, err, status = Open3.capture3(*command, stdin_data: key_presses)
        raise "Command failed: #{[out, err].join}" unless status.success?

        [out, File.read("Gemfile"), File.read("Gemfile.lock")]
      end
    end

    def within_fixture_copy(fixture, &block)
      fixture_path = File.join(File.expand_path("../fixtures", __dir__), fixture)
      Dir.mktmpdir do |tmp|
        FileUtils.cp_r(fixture_path, tmp)
        Dir.chdir(File.join(tmp, File.basename(fixture_path)), &block)
      end
    end

    def fetch_latest_gem_version_from_rubygems_api(name)
      WebMock.allow_net_connect!
      VCR.turned_off do
        response = HTTP.get("https://rubygems.org/api/v1/gems/#{name}.json")
        raise unless response.success?

        JSON.parse(response.body)["version"]
      end
    ensure
      WebMock.disable_net_connect!
    end
  end
end
