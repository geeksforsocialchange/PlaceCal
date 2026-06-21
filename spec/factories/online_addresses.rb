# frozen_string_literal: true

# == Schema Information
#
# Table name: online_addresses
#
#  id         :bigint           not null, primary key
#  link_type  :string
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :online_address do
    url { Faker::Internet.url }
    link_type { "indirect" }

    factory :direct_online_address do
      url { "https://zoom.us/j/1234567890" }
      link_type { "direct" }
    end
  end
end
