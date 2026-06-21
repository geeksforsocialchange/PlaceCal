# frozen_string_literal: true

# == Schema Information
#
# Table name: supporters
#
#  id          :bigint           not null, primary key
#  description :string
#  is_global   :boolean          default(FALSE), not null
#  logo        :string
#  name        :string           not null
#  url         :string
#  weight      :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :supporter do
    sequence(:name) { |n| "Supporter #{n}" }
    url { Faker::Internet.url }
    description { Faker::Lorem.sentence }
  end
end
