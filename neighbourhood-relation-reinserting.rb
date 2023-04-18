# a hack for bulk lookup of postcodes

require './config/environment'

count = 0
bad_neighbourhood_count = 0

File.open('./neighbourhood-relation-data.json').each_line do |line|
  count += 1

  data = JSON.parse(line.strip)

  ward_code = data['code']
  # name
  # name_abbr
  sites = data['sites']
  users = data['users']
  service_areas = data['service_areas']

  # next if sites.empty? && users.empty? && service_areas.empty?

  print "#{ward_code}  "
  
  # puts "#{ward_code}  #{sites.count} #{users.count} #{service_areas.count}"
  neighbourhood = Neighbourhood.where(unit_code_value: ward_code).first

  if neighbourhood.nil?
    bad_neighbourhood_count += 1
    puts "no neighbourhood found"
    next
  end

  # do updating bits now ...
  puts "neighbourhood=#{neighbourhood.id}"
end

puts "processed #{count} neighbourhoods (#{bad_neighbourhood_count} bad neighboudhoods)"
