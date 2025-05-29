# frozen_string_literal: true

module SeedTags
  def self.run
    $stdout.puts 'Sites'

    Site.create!(
      name: 'Default Site',
      slug: 'default-site',
      url: 'http://default-site.lvh.me:3000'
    )
  end
end

SeedTags.run
