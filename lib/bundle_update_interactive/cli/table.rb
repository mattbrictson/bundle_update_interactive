# frozen_string_literal: true

require "pastel"

class BundleUpdateInteractive::CLI
  class Table
    HEADERS = ["name", "from", nil, "to", "group", "url"].freeze

    def initialize(outdated_gems)
      @pastel = Pastel.new
      @headers = HEADERS.map { |h| pastel.dim.underline(h) }
      @rows = outdated_gems.transform_values { |gem| Row.new(gem).to_a.map(&:to_s) }
      @column_widths = calculate_column_widths
    end

    def gem_names
      rows.keys
    end

    def render_header
      render_row(headers)
    end

    def render_gem(name)
      row = rows.fetch(name)
      render_row(row)
    end

    def render
      lines = [render_header]
      rows.each_key { |name| lines << render_gem(name) }
      lines.join("\n")
    end

    private

    attr_reader :column_widths, :pastel, :rows, :headers

    def render_row(row)
      row.zip(column_widths).map do |value, width|
        padding = width && (" " * (width - pastel.strip(value).length))
        "#{value}#{padding}"
      end.join("  ")
    end

    def calculate_column_widths
      rows_with_header = [headers, *rows.values]
      Array.new(headers.length - 1) do |i|
        rows_with_header.map { |values| pastel.strip(values[i]).length }.max
      end
    end
  end
end
