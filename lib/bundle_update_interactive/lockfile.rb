# frozen_string_literal: true

require "bundler"
require "set"

module BundleUpdateInteractive
  class Lockfile
    def self.parse(lockfile_contents=File.read("Gemfile.lock"))
      parser = Bundler::LockfileParser.new(lockfile_contents)
      new(parser.specs)
    end

    def initialize(specs)
      @specs_by_name = {}
      required_exactly = Set.new

      specs.each do |spec|
        specs_by_name[spec.name] = spec
        spec.dependencies.each { |dep| required_exactly << dep.name if dep.requirement.exact? }
      end

      @entries_by_name = specs_by_name.transform_values do |spec|
        build_entry(spec, required_exactly.include?(spec.name))
      end
    end

    def entries
      entries_by_name.values
    end

    def [](gem_name)
      entries_by_name[gem_name]
    end

    private

    attr_reader :entries_by_name, :specs_by_name

    def build_entry(spec, exact)
      exact_dependencies = traverse_transient_dependencies(spec.name) { |dep| dep.requirement.exact? }
      LockfileEntry.new(spec, exact_dependencies, exact)
    end

    def traverse_transient_dependencies(*gem_names) # rubocop:disable Metrics/AbcSize
      traversal = Set.new
      stack = gem_names.flatten
      until stack.empty?
        specs_by_name[stack.pop].dependencies.each do |dep|
          next if traversal.include?(dep.name)
          next unless specs_by_name.key?(dep.name)
          next if block_given? && !yield(dep)

          traversal << dep.name
          stack << dep.name
        end
      end
      traversal.to_a
    end
  end
end
