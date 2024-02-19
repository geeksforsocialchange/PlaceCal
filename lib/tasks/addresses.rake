# frozen_string_literal: true

# TODO? Move this to events.rake ?   events.rake contains namespace :import
namespace :events do
  desc 'Set Event#address from Event#place.address for Events that do not have an Address'
  task set_missing_addresses_from_place: :environment do
    events = Event.where(address_id: nil).where.not(place_id: nil)
    $stdout.puts "Updating #{events.count} Events:"
    num = 1
    events.each do |e|
      $stdout.puts "#{num}: #{e.summary}, #{e.place.name}"
      e.place = e.place
      e.save
      num += 1
    end
  end
end
