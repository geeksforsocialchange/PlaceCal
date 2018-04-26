FactoryBot.define do
  factory(:place) do
    name 'Zion Centre'
    address
    after(:build) do |place|
      place.turfs << FactoryBot.create(:turf)
    end
  end
end
