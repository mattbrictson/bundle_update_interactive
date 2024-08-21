# frozen_string_literal: true

# lib/bundle_update_interactive/string_helper.rb
module BundleUpdateInteractive
  module StringHelper
    def pluralize(count, singular, plural = nil)
      plural ||= "#{singular}s"
      "#{count} #{count == 1 ? singular : plural}"
    end
    module_function :pluralize
  end
end