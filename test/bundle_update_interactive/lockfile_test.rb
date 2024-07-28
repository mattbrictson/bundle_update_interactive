# frozen_string_literal: true

require "test_helper"

module BundleUpdateInteractive
  class LockfileTest < Minitest::Test
    def test_parses_a_lockfile_into_entries_by_name
      lockfile = Lockfile.parse(File.read(File.expand_path("../fixtures/Gemfile.lock", __dir__)))

      assert_equal 83, lockfile.entries.size
      refute_nil(lockfile.entries.find { |entry| entry.name == "rails" })

      rails_entry = lockfile["rails"]
      assert_equal "rails", rails_entry.name
      assert_instance_of LockfileEntry, rails_entry
    end

    def test_finds_exact_dependencies
      lockfile = Lockfile.parse(File.read(File.expand_path("../fixtures/Gemfile.lock", __dir__)))

      assert_equal(
        %w[
          actioncable
          actionmailbox
          actionmailer
          actionpack
          actiontext
          actionview
          activejob
          activemodel
          activerecord
          activestorage
          activesupport
          railties
        ],
        lockfile["rails"].exact_dependencies.sort
      )

      assert_empty lockfile["activesupport"].exact_dependencies
    end

    def test_denotes_entries_that_are_locked_by_exact_dependency_requirements
      lockfile = Lockfile.parse(File.read(File.expand_path("../fixtures/Gemfile.lock", __dir__)))

      assert_predicate lockfile["activesupport"], :exact_requirement?
      assert_predicate lockfile["railties"], :exact_requirement?
      refute_predicate lockfile["rails"], :exact_requirement?
      refute_predicate lockfile["nokogiri"], :exact_requirement?
    end

    def test_gems_exclusively_installed_by_development_and_test_groups
      gemfile = Gemfile.parse(File.expand_path("../fixtures/Gemfile", __dir__))
      lockfile = Lockfile.parse(File.read(File.expand_path("../fixtures/Gemfile.lock", __dir__)))
      exclusively_installed = lockfile.gems_exclusively_installed_by(gemfile: gemfile, groups: %i[development test])

      assert_equal(
        %w[
          addressable
          bindex
          capybara
          debug
          matrix
          public_suffix
          regexp_parser
          rexml
          rubyzip
          selenium-webdriver
          web-console
          websocket
          xpath
        ],
        exclusively_installed.sort
      )
    end

    def test_gems_exclusively_installed_by_no_groups_is_empty_array
      gemfile = Gemfile.parse(File.expand_path("../fixtures/Gemfile", __dir__))
      lockfile = Lockfile.parse(File.read(File.expand_path("../fixtures/Gemfile.lock", __dir__)))
      exclusively_installed = lockfile.gems_exclusively_installed_by(gemfile: gemfile, groups: [])

      assert_empty exclusively_installed
    end
  end
end
