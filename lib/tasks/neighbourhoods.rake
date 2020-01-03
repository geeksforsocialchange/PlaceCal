# This rake task creates the database migration needed to add ward info
# Data: https://geoportal.statistics.gov.uk/datasets/ward-to-local-authority-district-to-county-to-region-to-country-december-2018-lookup-in-united-kingdom-

namespace :neighbourhoods do
  desc 'Import UK ward and county data'
  task import_wards: :environment do
    input_file = Rails.root.join('lib/data/Ward_to_Local_Authority_District_to_County_to_Region_to_Country_December_2018_Lookup_in_United_Kingdom_.csv')
    data = CSV.open(input_file, headers: true, header_converters: :symbol)
    data.each do |row|
      puts row.to_hash
      break
    end
  end
end
