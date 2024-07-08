require "thor"

module BundleUpdateInteractive
  class CLI < Thor
    extend ThorExt::Start

    map %w[-v --version] => "version"

    desc "version", "Display bundle_update_interactive version", hide: true
    def version
      say "bundle_update_interactive/#{VERSION} #{RUBY_DESCRIPTION}"
    end
  end
end
