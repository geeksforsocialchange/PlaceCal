# frozen_string_literal: true

module SeedTags
  def self.run
    $stdout.puts 'Sites'

    Site.create!(
      name: 'Default Site',
      slug: 'default-site',
      url: 'http://default-site.lvh.me:3000'
    )
    area = Neighbourhood.create!(
      name: 'Ad Astra',
      name_abbr: 'Ad Astra',
      unit: 'country',
      unit_code_key: 'CTRY99AA',
      unit_code_value: 'E90210aaa',
      unit_name: 'Ad Astra',
      release_date: DateTime.now
    )
    Site.create!(
      name: 'Ad Astra',
      slug: 'ad-astra',
      url: 'http://ad-astra.lvh.me:3000',
      is_published: true,
      primary_neighbourhood: area
    )
  end
end

SeedTags.run
