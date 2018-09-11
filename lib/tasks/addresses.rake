namespace :addresses do

  # TODO: Refactor these two tasks to use a lower level task
  desc "Geocode all addresses in order to identify neighbourhood turfs"
  task update_neighbourhood_turfs: :environment do
    $stdout.puts "Regeocoding #{Address.count} Addresses:"
    num = 1
    Address.all.each do |a|
      $stdout.puts "#{num}: #{a.street_address}, #{a.postcode}"
      a.force_geocoding
      num+=1
    end
  end

  desc "Geocode addresses that do not have a neighbourhood turf"
  task set_missing_neighbourhood_turfs: :environment do
    $stdout.puts "Geocoding #{Address.where( neighbourhood_turf: nil ).count} Addresses:"
    num = 1
    Address.where( neighbourhood_turf: nil ).each do |a|
      $stdout.puts "#{num}: #{a.street_address}, #{a.postcode}"
      a.force_geocoding
      num+=1
    end
  end
end
