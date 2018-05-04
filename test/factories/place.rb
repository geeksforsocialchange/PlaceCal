FactoryBot.define do
  factory(:place) do
    name Faker::Address.community
    address
    after(:build) do |place|
      place.turfs << FactoryBot.create(:turf)
    end
  end
end
