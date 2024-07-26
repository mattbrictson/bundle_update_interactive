# frozen_string_literal: true

require "test_helper"
require "tty/prompt/test"

class BundleUpdateInteractive::CLI
  class MultiSelectTest < Minitest::Test
    ARROW_UP = "\e[A"
    ARROW_DOWN = "\e[B"
    CTRL_A = "\u0001"
    CTRL_R = "\u0012"

    def setup
      @table = Table.new(
        "a" => build(:outdated_gem, name: "a", rubygems_source: false),
        "b" => build(:outdated_gem, name: "b", rubygems_source: false),
        "c" => build(:outdated_gem, name: "c", rubygems_source: false)
      )
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

    private

    def use_menu_with_keypress(*keys)
      prompt = TTY::Prompt::Test.new
      prompt.input << keys.join
      prompt.input << "\n"
      prompt.input.rewind

      multi_select = MultiSelect.new(title: "", table: @table, prompt: prompt)
      multi_select.prompt
    end
  end
end
