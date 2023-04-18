# a hack for bulk lookup of postcodes

require './config/environment'

postcode_count = 0
invalid_count = 0
bad_response_count = 0
missing_neighbourhood_count = 0

File.open('./postcodes.txt').each_line do |line|
  postcode_count += 1
  postcode = line.gsub(/\W/, '')

  print "#{postcode}  "

  okay = UKPostcode.parse(postcode).full_valid?
  if !okay
    invalid_count += 1
    puts "invalid"
    next
  end
  
  sleep 0.25
  
  req = HTTParty.get("https://api.postcodes.io/postcodes/#{postcode}")
  # puts req.status
  if req.code != 200
    bad_response_count += 1
    puts "failed lookup #{req.code}"
    next
  end
  
  payload = JSON.parse(req.body)
  res = payload['result']
  
  # based on app/models/neighbourhood.rb:105
  unit_code_value = res['codes']['admin_ward']
  unit_name = res['admin_ward']

  print "\"#{res['postcode']}\"  #{unit_code_value}  \"#{unit_name}\"    "

  neighbourhood = Neighbourhood.where(
    # unit: 'ward',
    # unit_code_key: 'WD19CD',
    unit_code_value: unit_code_value #,
    # unit_name: unit_name

  ).first

  if neighbourhood.nil?
    missing_neighbourhood_count += 1
    next
  end
  
  puts "neighbourhood=#{neighbourhood.id}"
end

puts "done."
puts "               postcode_count = #{postcode_count}"
puts "                invalid_count = #{invalid_count}"
puts "           bad_response_count = #{bad_response_count}"
puts "  missing_neighbourhood_count = #{missing_neighbourhood_count}"
