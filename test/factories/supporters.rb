# frozen_string_literal: true

# test/factories/supporter.rb
FactoryBot.define do
  factory :supporter do
    name { "Kind Supporter" }
    url { "http://example.com" }
    logo { "sponsor-logo.png" }
    description { "A nice desecription of our lovely supporter" }
    weight { 1 }
  end
end
