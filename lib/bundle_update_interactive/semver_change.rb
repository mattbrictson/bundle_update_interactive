# frozen_string_literal: true

module BundleUpdateInteractive
  class SemverChange
    SEVERITIES = %i[major minor patch].freeze

    def initialize(old_version, new_version)
      old_segments = old_version.to_s.split(".")
      new_segments = new_version.to_s.split(".")

      @same_segments = new_segments.take_while.with_index { |seg, i| seg == old_segments[i] }
      @diff_segments = new_segments[same_segments.length..]

      @changed = diff_segments.any? || old_segments.length != new_segments.length
    end

    def severity
      return nil unless @changed

      SEVERITIES[same_segments.length] || :patch
    end

    SEVERITIES.each do |level|
      define_method(:"#{level}?") { severity == level }
    end

    def none?
      severity.nil?
    end

    def any?
      !!severity
    end

    def format
      parts = []
      parts << same_segments.join(".") if same_segments.any?
      parts << yield(diff_segments.join(".")) if diff_segments.any?
      parts.join(".")
    end

    private

    attr_reader :same_segments, :diff_segments
  end
end
