namespace :addresses do

  # TODO: Refactor these two tasks to use a lower level task
  desc "Geocode all addresses in order to identify neighbourhood turfs"
  task update_all_neighbourhood_turfs: :environment do
    $stdout.puts "Regeocoding #{Address.count} Addresses:"
    num = 1
    Address.all.each do |a|
      $stdout.puts "#{num}: #{a.street_address}, #{a.postcode}"
      a.geocode_with_ward
      a.save
      num+=1
    end
  end

  desc "Geocode addresses that do not have a neighbourhood turf"
  task set_missing_neighbourhood_turfs: :environment do
    $stdout.puts "Geocoding #{Address.where( neighbourhood_turf: nil ).count} Addresses:"
    num = 1
    Address.where( neighbourhood_turf: nil ).each do |a|
      $stdout.puts "#{num}: #{a.street_address}, #{a.postcode}"
      a.geocode_with_ward
      a.save
      num+=1
    end
  end
end

# TODO? Move this to events.rake ?   events.rake contains namespace :import
namespace :events do
  desc "Set Event#address from Event#place.address for Events that do not have an Address"
  task set_missing_addresses_from_place: :environment do
    events = Event.where( address_id: nil ).where.not( place_id: nil )
    $stdout.puts "Updating #{events.count} Events:"
    num = 1
    events.each do |e|
      $stdout.puts "#{num}: #{e.summary}, #{e.place.name}"
      e.place = e.place
      e.save
      num+=1
    end
  end
end
