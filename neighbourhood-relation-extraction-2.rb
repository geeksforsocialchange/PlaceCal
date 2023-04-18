require './config/environment'

# saves neighbourhood Users, Service Areas, Addresses and Sites


module Extractor
  extend self

  def run
    payload = {}

    payload[:users] = process_users
    payload[:service_area_partners] = process_partners
    payload[:addresses] = process_addresses
    payload[:sites] = process_sites

    File.open('neighbourhood-relation-info.json', 'w') do |file|
      file.puts payload.to_json
    end
  end

  def process_users
    found = {}
    
    User.all.each do |user|
      user[user.id] = user.neighbourhoods.pluck(:unit_code_value)
    end

    found
  end

  def process_partners # service areas
    found = {}

    Partner.all.each do |partner|
      found[partner.id] = partner.service_areas.pluck(:unit_code_value)
    end
    
    found
  end

  def process_addresses
    found = {}
    
    Address.all.each do |address|
      found[address.id] = address.neighbourhood.unit_code_value
    end
    
    found
  end

  def process_sites
    found = {}

    Site.all.each do |site|
      found[site.id] = site.neighbourhoods.pluck(:unit_code_value)
    end
    
    found
  end
end

Extractor.run
