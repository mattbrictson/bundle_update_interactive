# frozen_string_literal: true

require "launchy"
require "pastel"
require "tty/prompt"
require "tty/screen"

class BundleUpdateInteractive::CLI
  class MultiSelect
    class List < TTY::Prompt::MultiList
      def initialize(prompt, **options)
        @opener = options.delete(:opener)
        defaults = {
          cycle: true,
          help_color: :itself.to_proc,
          per_page: [TTY::Prompt::Paginator::DEFAULT_PAGE_SIZE, TTY::Screen.height.to_i - 3].max,
          quiet: true,
          show_help: :always
        }
        super(prompt, **defaults.merge(options))
      end

      def selected_names
        ""
      end

      # Unregister tty-prompt's default ctrl-a and ctrl-r bindings
      alias select_all keyctrl_a
      alias reverse_selection keyctrl_r
      def keyctrl_a(*); end
      def keyctrl_r(*); end

      def keypress(event)
        case event.value
        when "k", "p" then keyup
        when "j", "n" then keydown
        when "a" then select_all
        when "r" then reverse_selection
        when "o" then opener&.call(choices[@active - 1].value)
        end
      end

      private

      attr_reader :opener
    end

    def self.prompt_for_gems_to_update(outdated_gems, prompt: nil)
      table = Table.new(outdated_gems)
      title = "#{outdated_gems.length} gems can be updated."
      opener = lambda do |gem|
        url = outdated_gems[gem].changelog_uri
        Launchy.open(url) unless url.nil?
      end
      chosen = new(title: title, table: table, prompt: prompt, opener: opener).prompt
      outdated_gems.slice(*chosen)
    end

    def initialize(title:, table:, opener: nil, prompt: nil)
      @title = title
      @table = table
      @opener = opener
      @tty_prompt = prompt || TTY::Prompt.new(
        interrupt: lambda {
          puts
          exit(130)
        }
      )
      @pastel = BundleUpdateInteractive.pastel
    end

    def prompt
      choices = table.gem_names.to_h { |name| [table.render_gem(name), name] }
      tty_prompt.invoke_select(List, title, choices, help: help, opener: opener)
    end

    private

    attr_reader :pastel, :table, :opener, :tty_prompt, :title

    def help
      [
        pastel.dim("\nPress <space> to select, ↑/↓ move, <a> all, <r> reverse, <o> open url, <enter> to finish."),
        "\n    ",
        table.render_header
      ].join
    end
  end
end
