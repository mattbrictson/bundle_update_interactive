# frozen_string_literal: true

require "factory_bot"

FactoryBot.find_definitions

class Minitest::Test
  include FactoryBot::Syntax::Methods
end
