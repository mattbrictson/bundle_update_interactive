# frozen_string_literal: true

FactoryBot.define do
  factory :outdated_gem, class: "BundleUpdateInteractive::OutdatedGem" do
    current_git_version { nil }
    current_version { "7.0.3" }
    git_source_uri { nil }
    name { "rails" }
    rubygems_source { true }
    updated_git_version { nil }
    updated_version { "7.1.0" }
    vulnerable { false }
  end
end
