# frozen_string_literal: true

source "https://rubygems.org"
gemspec

gem "activesupport", "~> 7.1.3" # Needed for factory_bot 6.3
gem "cgi" # Needed for vcr on Ruby 3.5+
gem "factory_bot", "~> 6.3.0"
gem "minitest", "~> 5.11"
gem "minitest-snapshots", "~> 1.1"
gem "mocha", "~> 2.4"
gem "observer"
gem "rake", "~> 13.0"
gem "vcr", "~> 6.2"
gem "webmock", "~> 3.23"

if RUBY_VERSION >= "3.3"
  gem "mighty_test", "~> 0.3"
  gem "rubocop", "1.80.1"
  gem "rubocop-factory_bot", "2.27.1"
  gem "rubocop-minitest", "0.38.2"
  gem "rubocop-packaging", "0.6.0"
  gem "rubocop-performance", "1.26.0"
  gem "rubocop-rake", "0.7.1"
end
