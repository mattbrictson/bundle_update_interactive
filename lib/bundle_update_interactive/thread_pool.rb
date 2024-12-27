# frozen_string_literal: true

require "concurrent"

module BundleUpdateInteractive
  class ThreadPool
    include Concurrent::Promises::FactoryMethods

    def initialize(max_threads:)
      @executor = Concurrent::ThreadPoolExecutor.new(
        min_threads: 0,
        max_threads: max_threads,
        max_queue: 0
      )
    end

    def default_executor
      @executor
    end
  end
end
