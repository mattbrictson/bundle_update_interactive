# frozen_string_literal: true

require "bundler"

module BundleUpdateInteractive
  class Gemfile
    def self.parse(path="Gemfile")
      dsl = Bundler::Dsl.new
      dsl.eval_gemfile(path)
      dependencies = dsl.dependencies.to_h { |d| [d.name, d] }
      new(dependencies)
    end

    def initialize(dependencies)
      @dependencies = dependencies.freeze
    end

    def [](name)
      @dependencies[name]
    end
  end
end
