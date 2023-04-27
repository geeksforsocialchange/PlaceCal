require './config/environment'

# saves neighbourhood Users, Service Areas, Addresses and Sites


module Extractor
  extend self

  def run
    payload = {}

    payload[:timestamp] = Time.now.to_s
    puts "running on #{payload[:timestamp]}"
    
    payload[:users] = process_users
    puts "users.count=#{payload[:users].count}"

    payload[:service_area_partners] = process_partners
    puts "service_area_partners.count=#{payload[:service_area_partners].count}"

    payload[:addresses] = process_addresses
    puts "addresses.count=#{payload[:addresses].count}"

    payload[:sites] = process_sites
    puts "sites.count=#{payload[:sites].count}"

    File.open('neighbourhood-relation-info.json', 'w') do |file|
      file.puts payload.to_json
    end
  end

  def process_users
    found = {}
    
    User.all.each do |user|
      found[user.id] = user.neighbourhoods.pluck(:unit_code_value)
    end

    found
  end

  def process_partners # service areas
    found = {}

    Partner.all.each do |partner|
      found[partner.id] = partner.service_area_neighbourhoods.pluck(:unit_code_value)
    end
    
    found
  end

  def process_addresses
    found = {}
    
    Address.all.each do |address|
      hood = address.neighbourhood
      next if hood.nil?
      
      found[address.id] = hood.unit_code_value
    end
    
    found
  end

  def process_sites
    found = {}

    Site.all.each do |site|
      found[site.id] = {
        primary: site.primary_neighbourhood&.unit_code_value,
        secondary: site.secondary_neighbourhoods.pluck(:unit_code_value)
      }
    end
    
    found
  end
end

Extractor.run

=begin
given an import job where data must be reconciled between data
that exists in the DB and data present in the snapshot files,
key off of data in the DB.

so this
Partner.each do |partner|

service_areas = import_data[:partners][partner.id]

service_areas.each do |unit_code|
neighbourhood = Neighbourhood.where(unit_code: unit_code).first
if neighbourhood.nil?
we are mising a neighbourhood for partner ID
next
end
end
end

=end
