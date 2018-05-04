FactoryBot.define do
  factory :turf do
    name Faker::Address.city
    slug { name.parameterize }
  end
end
