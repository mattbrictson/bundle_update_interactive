# frozen_string_literal: true

require "test_helper"
require "launchy"
require "tty/prompt/test"

class BundleUpdateInteractive::CLI
  class MultiSelectTest < Minitest::Test
    ARROW_UP = "\e[A"
    ARROW_DOWN = "\e[B"
    CTRL_A = "\u0001"
    CTRL_R = "\u0012"

    def setup
      @outdated_gems = {
        "a" => build(:outdated_gem, name: "a", changelog_uri: nil),
        "b" => build(:outdated_gem, name: "b", changelog_uri: "https://b.example.com/"),
        "c" => build(:outdated_gem, name: "c", changelog_uri: "https://c.example.com/")
      }
    end

    def test_pressing_a_selects_all_rows
      selected = use_menu_with_keypress "a"

      assert_equal %w[a b c], selected
    end

    def test_pressing_space_then_r_selects_all_but_the_first_row
      selected = use_menu_with_keypress " ", "r"

      assert_equal %w[b c], selected
    end

    def test_pressing_down_then_space_selects_the_second_row
      selected = use_menu_with_keypress ARROW_DOWN, " "

      assert_equal %w[b], selected
    end

    def test_pressing_j_then_space_selects_the_second_row
      selected = use_menu_with_keypress "j", " "

      assert_equal %w[b], selected
    end

    def test_pressing_k_then_space_selects_the_last_row
      selected = use_menu_with_keypress "k", " "

      assert_equal %w[c], selected
    end

    def test_pressing_up_then_space_selects_the_last_row
      selected = use_menu_with_keypress ARROW_UP, " "

      assert_equal %w[c], selected
    end

    def test_pressing_ctrl_a_has_no_effect
      selected = use_menu_with_keypress CTRL_A

      assert_empty selected
    end

    def test_pressing_ctrl_r_has_no_effect
      selected = use_menu_with_keypress CTRL_R

      assert_empty selected
    end

    def test_pressing_down_then_o_opens_changelog_uri_of_second_gem_in_browser
      Launchy.expects(:open).with("https://b.example.com/").once

      use_menu_with_keypress ARROW_DOWN, "o"
    end

    def test_pressing_o_for_gem_with_no_changelog_does_nothing
      Launchy.expects(:open).never

      use_menu_with_keypress "o"
    end

    private

    def use_menu_with_keypress(*keys)
      prompt = TTY::Prompt::Test.new
      prompt.input << keys.join
      prompt.input << "\n"
      prompt.input.rewind

      selected = MultiSelect.prompt_for_gems_to_update(@outdated_gems, prompt: prompt)
      selected.keys
    end
  end
end
