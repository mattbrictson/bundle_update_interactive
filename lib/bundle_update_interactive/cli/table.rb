# frozen_string_literal: true

require "pastel"

module BundleUpdateInteractive
  class CLI
    class Table
      class << self
        def withheld(gems)
          columns = [
            ["name", :formatted_gem_name],
            ["requirement", :formatted_gemfile_requirement],
            ["current", :formatted_current_version],
            ["latest", :formatted_updated_version],
            ["group", :formatted_gemfile_groups],
            ["url", :formatted_changelog_uri]
          ]
          new(gems, columns)
        end

        def updatable(gems)
          columns = [
            ["name", :formatted_gem_name],
            ["from", :formatted_current_version],
            [nil, "→"],
            ["to", :formatted_updated_version],
            ["group", :formatted_gemfile_groups],
            ["url", :formatted_changelog_uri]
          ]
          new(gems, columns)
        end
      end

      def initialize(gems, columns)
        @pastel = BundleUpdateInteractive.pastel
        @headers = columns.map { |header, _| pastel.dim.underline(header) }
        @rows = gems.transform_values do |gem|
          row = Row.new(gem)
          columns.map do |_, col|
            case col
            when Symbol then row.public_send(col).to_s
            when String then col
            end
          end
        end
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
        rows.keys.sort.each { |name| lines << render_gem(name) }
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
end
