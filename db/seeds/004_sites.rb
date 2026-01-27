# frozen_string_literal: true

require_relative '../../lib/normal_island'

module SeedSites
  def self.run
    $stdout.puts 'Sites'

    # Default site (covers all of Normal Island)
    default_site = Site.create!(
      name: NormalIsland::SITES[:normal_island_central][:name],
      slug: NormalIsland::SITES[:normal_island_central][:slug],
      tagline: NormalIsland::SITES[:normal_island_central][:tagline],
      url: 'http://default-site.lvh.me:3000'
    )
    $stdout.puts "  Created site: #{default_site.name}"

    # Millbrook Community Calendar
    millbrook_district = Neighbourhood.find_by(name: 'Millbrook')
    if millbrook_district
      millbrook_site = Site.create!(
        name: NormalIsland::SITES[:millbrook_community_calendar][:name],
        slug: NormalIsland::SITES[:millbrook_community_calendar][:slug],
        tagline: NormalIsland::SITES[:millbrook_community_calendar][:tagline],
        url: 'http://millbrook.lvh.me:3000',
        is_published: true,
        primary_neighbourhood: millbrook_district
      )
      $stdout.puts "  Created site: #{millbrook_site.name}"
    end

    # Ashdale Connect
    ashdale_district = Neighbourhood.find_by(name: 'Ashdale')
    if ashdale_district
      ashdale_site = Site.create!(
        name: NormalIsland::SITES[:ashdale_connect][:name],
        slug: NormalIsland::SITES[:ashdale_connect][:slug],
        tagline: NormalIsland::SITES[:ashdale_connect][:tagline],
        url: 'http://ashdale.lvh.me:3000',
        is_published: true,
        primary_neighbourhood: ashdale_district
      )
      $stdout.puts "  Created site: #{ashdale_site.name}"
    end

    # Coastshire Events
    coastshire_county = Neighbourhood.find_by(name: 'Coastshire')
    return unless coastshire_county

    coastshire_site = Site.create!(
      name: NormalIsland::SITES[:coastshire_events][:name],
      slug: NormalIsland::SITES[:coastshire_events][:slug],
      tagline: NormalIsland::SITES[:coastshire_events][:tagline],
      url: 'http://coastshire.lvh.me:3000',
      is_published: true,
      primary_neighbourhood: coastshire_county
    )
    $stdout.puts "  Created site: #{coastshire_site.name}"
  end
end

SeedSites.run
