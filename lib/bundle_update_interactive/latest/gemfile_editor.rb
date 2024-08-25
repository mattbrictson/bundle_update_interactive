# frozen_string_literal: true

module BundleUpdateInteractive
  module Latest
    class GemfileEditor
      def initialize(gemfile_path: "Gemfile", lockfile_path: "Gemfile.lock")
        @gemfile_path = gemfile_path
        @lockfile_path = lockfile_path
      end

      def with_relaxed_gemfile
        original, modified = modify_gemfile { |_, requirement| requirement.relax }
        yield
      ensure
        File.write(gemfile_path, original) if original && original != modified
      end

      def shift_gemfile
        lockfile = Lockfile.parse(File.read(lockfile_path))
        original, modified = modify_gemfile do |name, requirement|
          lockfile_entry = lockfile[name]
          requirement.shift(lockfile_entry.version.to_s) if lockfile_entry
        end
        original != modified
      end

      private

      attr_reader :gemfile_path, :lockfile_path

      def modify_gemfile(&block)
        original_contents = File.read(gemfile_path)
        new_contents = original_contents.dup

        find_rewritable_gem_names(original_contents).each do |name|
          rewrite_contents(name, new_contents, &block)
        end

        File.write(gemfile_path, new_contents) unless new_contents == original_contents
        [original_contents, new_contents]
      end

      def find_rewritable_gem_names(contents)
        Gemfile.parse(gemfile_path).dependencies.filter_map do |dep|
          gem_name = dep.name
          gem_name if gem_declaration_with_requirement_re(gem_name).match?(contents)
        end
      end

      def rewrite_contents(gem_name, contents)
        found = contents.sub!(gem_declaration_with_requirement_re(gem_name)) do |match|
          version = Regexp.last_match[1]
          match[Regexp.last_match.regexp, 1] = yield(gem_name, GemRequirement.parse(version)).to_s
          match
        end
        raise "Can't rewrite version for #{gem_name}" unless found
      end

      def gem_declaration_re(gem_name)
        /^\s*gem\s+["']#{Regexp.escape(gem_name)}["']/
      end

      def gem_declaration_with_requirement_re(gem_name)
        /#{gem_declaration_re(gem_name)},\s*["']([^'"]+)["']/
      end
    end
  end
end
