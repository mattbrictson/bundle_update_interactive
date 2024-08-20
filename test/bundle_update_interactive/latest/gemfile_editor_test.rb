# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"

module BundleUpdateInteractive
  module Latest
    class GemfileEditorTest < Minitest::Test
      def setup
        @original_dir = Dir.pwd
        @temp_dir = Dir.mktmpdir
        Dir.chdir(Dir.mktmpdir)
      end

      def teardown
        Dir.chdir(@original_dir) if @original_dir
        FileUtils.rm_rf(@temp_dir) if @temp_dir
      end

      def test_with_relaxed_gemfile_doesnt_modify_gemfile_if_gemfile_lacks_specific_requirements
        original_gemfile = <<~GEMFILE
          source "https://rubygems.org"
          gem "sqlite3"
        GEMFILE
        File.write("Gemfile", original_gemfile)

        result = GemfileEditor.new.with_relaxed_gemfile do
          assert_equal original_gemfile, File.read("Gemfile")
          :done
        end

        assert_equal :done, result
      end

      def test_with_relaxed_gemfile_restores_original_gemfile_when_an_exception_is_raised
        original_gemfile = <<~GEMFILE
          source "https://rubygems.org"
          gem "sqlite3", "~> 1.7"
        GEMFILE

        File.write("Gemfile", original_gemfile)

        assert_raises(Interrupt) do
          GemfileEditor.new.with_relaxed_gemfile { raise Interrupt }
        end

        assert_equal original_gemfile, File.read("Gemfile")
      end

      def test_with_relaxed_gemfile_modifies_gemfile_then_restores_it_after_block_is_executed
        original_gemfile = <<~GEMFILE
          source "https://rubygems.org"
          gem "sqlite3", "~> 1.7"
        GEMFILE

        File.write("Gemfile", original_gemfile)

        result = GemfileEditor.new.with_relaxed_gemfile do
          assert_equal <<~GEMFILE, File.read("Gemfile")
            source "https://rubygems.org"
            gem "sqlite3", ">= 1.7"
          GEMFILE
          :done
        end

        assert_equal :done, result
        assert_equal original_gemfile, File.read("Gemfile")
      end

      def test_shift_gemfile_modifies_gemfile_based_on_versions_in_lock_file
        File.write("Gemfile", <<~GEMFILE)
          source "https://rubygems.org"
          gem "minitest", "~> 5.24.0"
        GEMFILE
        File.write("Gemfile.lock", <<~LOCK)
          GEM
            remote: https://rubygems.org/
            specs:
              minitest (5.25.1)

          PLATFORMS
            ruby

          DEPENDENCIES
            minitest (>= 5.24.0)

          BUNDLED WITH
             2.5.17
        LOCK

        gemfile_modified = GemfileEditor.new.shift_gemfile
        assert gemfile_modified
        assert_equal(<<~GEMFILE, File.read("Gemfile"))
          source "https://rubygems.org"
          gem "minitest", "~> 5.25.1"
        GEMFILE
      end

      def test_shift_gemfile_does_not_modify_gemfile_if_it_already_matches_lock_file
        original_gemfile = <<~GEMFILE
          source "https://rubygems.org"
          gem "minitest", "~> 5.25.0"
        GEMFILE
        File.write("Gemfile", original_gemfile)
        File.write("Gemfile.lock", <<~LOCK)
          GEM
            remote: https://rubygems.org/
            specs:
              minitest (5.25.1)

          PLATFORMS
            ruby

          DEPENDENCIES
            minitest (>= 5.24.0)

          BUNDLED WITH
             2.5.17
        LOCK

        gemfile_modified = GemfileEditor.new.shift_gemfile
        refute gemfile_modified
        assert_equal(original_gemfile, File.read("Gemfile"))
      end
    end
  end
end
