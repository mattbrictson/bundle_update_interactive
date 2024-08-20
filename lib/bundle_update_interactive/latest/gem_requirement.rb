# frozen_string_literal: true

module BundleUpdateInteractive
  module Latest
    class GemRequirement
      def self.parse(version)
        return version if version.is_a?(GemRequirement)

        version = version.strip
        _, operator, number = version.match(/^([^\d\s]*)\s*(.+)/).to_a
        operator = nil if operator.empty?

        new(parts: number.split("."), operator: operator)
      end

      attr_reader :parts, :operator

      def initialize(parts:, operator: nil)
        @parts = parts
        @operator = operator
      end

      def exact?
        operator.nil?
      end

      def relax
        return self if %w[!= > >=].include?(operator)
        return self.class.parse(">= 0") if %w[< <=].include?(operator)

        self.class.new(parts: parts, operator: ">=")
      end

      def shift(new_version) # rubocop:disable Metrics/AbcSize
        return self.class.parse(new_version) if exact?
        return self if Gem::Requirement.new(to_s).satisfied_by?(Gem::Version.new(new_version))
        return self.class.new(parts: self.class.parse(new_version).parts, operator: "<=") if %w[< <=].include?(operator)

        new_slice = self.class.parse(new_version).slice(parts.length)
        self.class.new(parts: new_slice.parts, operator: "~>")
      end

      def slice(amount)
        self.class.new(parts: parts[0, amount], operator: operator)
      end

      def to_s
        [operator, parts.join(".")].compact.join(" ")
      end

      def ==(other)
        return false unless other.is_a?(GemRequirement)

        to_s == other.to_s
      end
    end
  end
end
