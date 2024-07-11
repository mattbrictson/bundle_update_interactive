# frozen_string_literal: true

module BundleUpdateInteractive
  class LockfileEntry
    attr_reader :spec, :exact_dependencies

    def initialize(spec, exact_dependencies, exact_dependency)
      @spec = spec
      @exact_dependencies = exact_dependencies
      @exact_dependency = exact_dependency
    end

    def name
      spec.name
    end

    def version
      spec.version
    end

    def older_than?(updated_entry)
      return false if updated_entry.nil?

      if git_source? && updated_entry.git_source?
        version <= updated_entry.version && git_version != updated_entry.git_version
      else
        version < updated_entry.version
      end
    end

    def exact_dependency?
      @exact_dependency
    end

    def git_version
      spec.git_version&.strip
    end

    def git_source_uri
      spec.source.uri if git_source?
    end

    def git_source?
      !!git_version
    end

    def rubygems_source?
      return false if git_source?

      source = spec.source
      source.respond_to?(:remotes) && source.remotes.map(&:to_s).include?("https://rubygems.org/")
    end
  end
end
