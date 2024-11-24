# frozen_string_literal: true

require "factory_bot"

FactoryBot.find_definitions

module Minitest
  class Test
    include FactoryBot::Syntax::Methods
  end
end
