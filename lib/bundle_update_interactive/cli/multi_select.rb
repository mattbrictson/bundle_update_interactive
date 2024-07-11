# frozen_string_literal: true

require "pastel"
require "tty/prompt"
require "tty/screen"

class BundleUpdateInteractive::CLI
  class MultiSelect
    class List < TTY::Prompt::MultiList
      def initialize(prompt, **options)
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
    end

    def self.prompt_for_gems_to_update(outdated_gems)
      table = Table.new(outdated_gems)
      title = "#{outdated_gems.length} gems can be updated."
      chosen = new(title: title, table: table).prompt
      outdated_gems.slice(*chosen)
    end

    def initialize(title:, table:)
      @title = title
      @table = table
      @tty_prompt = TTY::Prompt.new(
        interrupt: lambda {
          puts
          exit(130)
        }
      )
      @pastel = Pastel.new
    end

    def prompt
      choices = table.gem_names.to_h { |name| [table.render_gem(name), name] }
      tty_prompt.invoke_select(List, title, choices, help: help)
    end

    private

    attr_reader :pastel, :table, :tty_prompt, :title

    def help
      [
        pastel.dim("\nPress <space> to select, ↑/↓ move, <ctrl-a> all, <ctrl-r> reverse, <enter> to finish."),
        "\n    ",
        table.render_header
      ].join
    end
  end
end
