# a hack for bulk lookup of postcodes

require './config/environment'

neighbourhood_map = []

def neighbourhood_needs_saving?(neighbourhood)
  return if neighbourhood.unit_code_value.blank?

  return true if neighbourhood.name_abbr.present?
  return true if neighbourhood.name != neighbourhood.unit_name
  return true if neighbourhood.sites.present?
  return true if neighbourhood.users.present?
  return true if neighbourhood.service_areas.present?
  
  neighbourhood.addresses.present?
end

Neighbourhood.all.each do |neighbourhood|
  next unless neighbourhood_needs_saving?(neighbourhood)

  sites = neighbourhood.sites.pluck(:id)
  users = neighbourhood.users.pluck(:id)
  service_areas = neighbourhood.service_areas.pluck(:id)

  neighbourhood_map << {
    code: neighbourhood.unit_code_value,
    name: neighbourhood.name,
    name_abbr: neighbourhood.name_abbr,
    sites: sites,
    users: users,
    service_areas: service_areas
  }
end

puts "processed #{neighbourhood_map.count} neighbourhoods"

File.open('neighbourhood-relation-data.json', 'w') do |file|
  neighbourhood_map.each do |neighbourhood_data|
    file.puts neighbourhood_data.to_json
  end
end
