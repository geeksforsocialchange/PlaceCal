# frozen_string_literal: true

require_relative '../../lib/normal_island'

module SeedSites # rubocop:disable Metrics/ModuleLength
  IMAGES_DIR = Rails.root.join('db/seeds/images')

  SITE_DATA = {
    normal_island_default: {
      place_name: 'Normal Island',
      hero_text: 'Community events across Normal Island',
      theme: :blue,
      hero_image: 'normal_island_hero.jpg',
      logo: 'normal_island_logo.svg'
    },
    normal_island_country: {
      place_name: 'Normal Island (country)',
      hero_text: 'Everything happening across Normal Island',
      theme: :pink,
      hero_image: 'normal_island_hero.jpg',
      logo: 'normal_island_logo.svg'
    },
    coastshire_county: {
      place_name: 'Coastshire (county)',
      hero_text: 'Events and activities on the coast',
      theme: :orange,
      hero_image: 'coastshire_hero.jpg',
      logo: 'coastshire_logo.svg'
    },
    millbrook_district: {
      place_name: 'Millbrook (district)',
      hero_text: 'What\'s on in Millbrook',
      theme: :blue,
      hero_image: 'millbrook_hero.jpg',
      logo: 'millbrook_logo.svg'
    }
  }.freeze

  def self.attach_images(site, data)
    hero_path = IMAGES_DIR.join(data[:hero_image])
    logo_path = IMAGES_DIR.join(data[:logo])

    site.hero_image = File.open(hero_path) if hero_path.exist?
    site.logo = File.open(logo_path) if logo_path.exist?
    site.save!
  end

  def self.ensure_primary_neighbourhood(site, neighbourhood)
    return unless neighbourhood

    existing = SitesNeighbourhood.find_by(site: site, neighbourhood: neighbourhood)
    if existing
      existing.update!(relation_type: 'Primary')
    else
      SitesNeighbourhood.create!(site: site, neighbourhood: neighbourhood, relation_type: 'Primary')
    end
  end

  def self.create_site(slug:, name:, tagline:, url:, data_key:, neighbourhood: nil, published: true) # rubocop:disable Metrics/ParameterLists
    site = Site.find_or_create_by!(slug: slug) do |s|
      s.name = name
      s.tagline = tagline
      s.url = url
      s.is_published = published
    end

    data = SITE_DATA[data_key]
    site.update!(
      name: name,
      place_name: data[:place_name],
      hero_text: data[:hero_text],
      theme: data[:theme],
      is_published: published
    )
    ensure_primary_neighbourhood(site, neighbourhood)
    attach_images(site, data)
    $stdout.puts "  Site: #{site.name} (#{site.slug})"
    site
  end

  def self.run
    $stdout.puts 'Sites'

    # Default site (fallback for no-subdomain requests)
    create_site(
      slug: 'default-site',
      name: 'Normal Island Central',
      tagline: 'Community events across Normal Island',
      url: 'http://default-site.lvh.me:3000',
      data_key: :normal_island_default,
      published: false
    )

    # Normal Island (country)
    create_site(
      slug: 'normal-island',
      name: 'Normal Island (country)',
      tagline: 'Everything happening across Normal Island',
      url: 'http://normal-island.lvh.me:3000',
      data_key: :normal_island_country,
      neighbourhood: Neighbourhood.find_by(name: 'Normal Island', unit: 'country')
    )

    # Coastshire (county)
    create_site(
      slug: 'coastshire',
      name: 'Coastshire (county)',
      tagline: 'Events and activities on the coast',
      url: 'http://coastshire.lvh.me:3000',
      data_key: :coastshire_county,
      neighbourhood: Neighbourhood.find_by(name: 'Coastshire', unit: 'county')
    )

    # Millbrook (district)
    create_site(
      slug: 'millbrook',
      name: 'Millbrook (district)',
      tagline: 'What\'s on in Millbrook',
      url: 'http://millbrook.lvh.me:3000',
      data_key: :millbrook_district,
      neighbourhood: Neighbourhood.find_by(name: 'Millbrook', unit: 'district')
    )
  end
end

SeedSites.run
