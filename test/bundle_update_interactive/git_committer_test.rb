# frozen_string_literal: true

require "test_helper"

module BundleUpdateInteractive
  class GitCommitterTest < Minitest::Test
    def setup
      @git_committer = GitCommitter.new(nil)
    end

    def test_format_commit_message
      gem = build(:outdated_gem, name: "activeadmin", current_version: "3.2.2", updated_version: "3.2.3")

      assert_equal "Update activeadmin 3.2.2 → 3.2.3", @git_committer.format_commit_message(gem)
    end

    def test_format_commit_message_with_git_version
      gem = build(
        :outdated_gem,
        name: "rails",
        current_version: "7.2.1",
        current_git_version: "5a8d894",
        updated_version: "7.2.1",
        updated_git_version: "77dfa65"
      )

      assert_equal "Update rails 7.2.1 5a8d894 → 7.2.1 77dfa65", @git_committer.format_commit_message(gem)
    end

    def test_apply_updates_as_individual_commits_raises_if_git_raises
      @git_committer.stubs(:`).with("git --version").raises(Errno::ENOENT)

      error = assert_raises(Error) { @git_committer.apply_updates_as_individual_commits }
      assert_equal "git could not be executed", error.message
    end

    def test_apply_updates_as_individual_commits_raises_if_git_does_not_succeed
      @git_committer.stubs(:`).with("git --version").returns("")
      Process.stubs(:last_status).returns(stub(success?: false))

      error = assert_raises(Error) { @git_committer.apply_updates_as_individual_commits }
      assert_equal "git could not be executed", error.message
    end

    def test_apply_updates_as_individual_commits_raises_if_there_are_uncommitted_files
      @git_committer.stubs(:`).with("git --version").returns("")
      @git_committer.stubs(:`).with("git status --untracked-files=no --porcelain").returns("M  Gemfile.lock")
      Process.stubs(:last_status).returns(stub(success?: true))

      error = assert_raises(Error) { @git_committer.apply_updates_as_individual_commits }
      assert_equal <<~MESSAGE.strip, error.message
        `git status` reports uncommitted changes; please commit or stash them them first!
        M  Gemfile.lock
      MESSAGE
    end
  end
end
