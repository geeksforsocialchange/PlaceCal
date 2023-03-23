# a hack for bulk lookup of postcodes

require './config/environment'

postcode_table = {}

=begin
CSV.foreach('/home/ivan/Downloads/geo-data/Data/NSPL_MAY_2022_UK.csv', headers: :first_row) do |row|
  postcode = row[0].to_s.strip
  ward_code = row[13].to_s.strip
  # next if postcode.empty? || ward_code.empty?

  postcode = postcode.gsub(/\W/, '')
  
  postcode_table[postcode] = ward_code
end
=end

bad_postcodes = ["EC1V2NX","M15","WC2N6HH","N193RQ","N19DN","N78TQ","KT12PT","SW40JL","W1W7LT","WC1N3XX","OL161AB","M40MOSTON","EX46NA","SM11EA","W1J7NF","UK","W1D6AQ","SW192HR","CR43UD","SW197NB","TW13AA","M114UA","M35DW","N19JP","UB79JL","SM51JJ","M144SQ","UB82DE","W139LA","UB83PH","M16","M144"]

bad_postcodes.each do |pc|
  print "#{pc}  "
  
  okay = UKPostcode.parse(pc).full_valid?
  if !okay
    puts "invalid"
    next
  end

  sleep 0.25
  
  req = HTTParty.get("https://api.postcodes.io/postcodes/#{pc}")
  # puts req.status
  if req.code != 200
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

  if neighbourhood
    puts "neighbourhood=#{neighbourhood.id}"
    next
  end

  
  # now try our own postcode db
  direct_lookup = postcode_table[pc]
  if direct_lookup.nil?
    puts "direct lookup failed"
    next
  end
  
  neighbourhood = Neighbourhood.where(
    # unit: 'ward',
    # unit_code_key: 'WD19CD',
    unit_code_value: direct_lookup #,
    # unit_name: unit_name
  ).first
  
  
  if neighbourhood.nil?
    puts "no neighbourhood from direct lookup"
    next
  end

  puts "neighbourhood (direct lookup) = #{neighbourhood.id}"
end

exit ##################################################################








postcode_table = {}

CSV.foreach('/home/ivan/Downloads/geo-data/Data/NSPL_MAY_2022_UK.csv', headers: :first_row) do |row|
  postcode = row[0].to_s.strip
  ward_code = row[13].to_s.strip
  # next if postcode.empty? || ward_code.empty?

  postcode_table[postcode] = ward_code
end

puts "Loaded #{postcode_table.count} postcodes"

# bad_postcodes = [] # ["EC1V2NX","M15","WC2N6HH","N193RQ","N19DN","N78TQ","KT12PT","SW40JL","W1W7LT","WC1N3XX","OL161AB","M40MOSTON","EX46NA","SM11EA","W1J7NF","UK","W1D6AQ","SW192HR","CR43UD","SW197NB","TW13AA","M114UA","M35DW","N19JP","UB79JL","SM51JJ","M144SQ","UB82DE","W139LA","UB83PH","M16","M144"]

bad_postcodes = ["EC1V2NX","M15","WC2N6HH","N193RQ","N19DN","N78TQ","KT12PT","SW40JL","W1W7LT","WC1N3XX","OL161AB","M40MOSTON","EX46NA","SM11EA","W1J7NF","UK","W1D6AQ","SW192HR","CR43UD","SW197NB","TW13AA","M114UA","N19JP","UB79JL","SM51JJ","M144SQ","UB82DE","W139LA","UB83PH","M16","M144"]



#File.open('./postcodes.txt').each_line do |line|

bad_postcodes.each do |postcode|
  sleep 0.5
  
  # postcode = line.gsub(/\W/, '')
  # postcode = UKPostcode.parse(line).to_s
  puts postcode

  res = postcode_table[postcode] # Geocoder.search(postcode).first&.data
  if res.nil?
    # bad_postcodes << postcode
    
    puts ",  no geocode response"
    next
  end

  next
  puts JSON.pretty_generate(res.as_json)

  # break
  
  neighbourhood = Neighbourhood.find_from_postcodesio_response(res)
  if neighbourhood.nil?
    # bad_postcodes << postcode
    puts "  no neighbourhood"
    next
  end

  puts "  neighbourhood=#{neighbourhood.id}"
end


# puts bad_postcodes.to_json
