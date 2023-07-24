# frozen_string_literal: true

module SeedTags
  def self.run
    $stdout.puts 'Sites'

    Site.create!(
      name: 'Default Site',
      slug: 'default-site',
      domain: 'default-site.placecal.org'
    )
  end
end

SeedTags.run
