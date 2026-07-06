# frozen_string_literal: true

FactoryBot.define do
  factory :email_subscription do
    user
    list_key { "partner_digest" }
    subscribed { true }
    source { "profile_page" }
  end
end
