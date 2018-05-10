FactoryBot.define do
  factory(:place) do
    sequence(:name) do |n|
      "Zion Center #{n}"
    end
    short_description 'A description of this Place'
    address
    after(:build) do |place|
      place.turfs << FactoryBot.create(:turf)
    end
  end
end
