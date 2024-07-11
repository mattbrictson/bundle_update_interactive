# frozen_string_literal: true

require "bundler"

module BundleUpdateInteractive
  class Lockfile
    # TODO: refactor
    def self.parse(lockfile_contents=File.read("Gemfile.lock")) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      parser = Bundler::LockfileParser.new(lockfile_contents)
      specs_by_name = {}
      exact = Set.new
      exact_children = {}

      parser.specs.each do |spec|
        specs_by_name[spec.name] = spec

        spec.dependencies.each do |dep|
          next unless dep.requirement.exact?

          exact << dep.name
          (exact_children[spec.name] ||= []) << dep.name
        end
      end

      entries = specs_by_name.transform_values do |spec|
        exact_dependencies = Set.new
        traversal = exact_children[spec.name]&.dup || []
        until traversal.empty?
          name = traversal.pop
          next if exact_dependencies.include?(name)

          exact_dependencies << name
          traversal.push(*exact_children.fetch(name, []))
        end

        LockfileEntry.new(spec, exact_dependencies, exact.include?(spec.name))
      end

      new(entries)
    end

    def initialize(entries)
      @entries = entries.freeze
    end

    def entries
      @entries.values
    end

    def [](gem_name)
      @entries[gem_name]
    end
  end
end
