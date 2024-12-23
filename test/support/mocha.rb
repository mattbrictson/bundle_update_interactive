# frozen_string_literal: true

require "mocha/minitest"

Mocha.configure do |config|
  config.stubbing_non_existent_method = :prevent
end
