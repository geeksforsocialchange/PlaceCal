# frozen_string_literal: true

require_relative '../../lib/normal_island'

module SeedPartners # rubocop:disable Metrics/ModuleLength
  LONG_TEXT = <<~LOREM_IPSUM
    Welcome to our community organisation! We provide a range of services and activities
    for local residents. Our friendly team is dedicated to supporting the community and
    creating opportunities for everyone to get involved.

    We offer regular events, workshops, and drop-in sessions throughout the week. Whether
    you're looking for social activities, learning opportunities, or just a friendly place
    to meet others, we're here for you.

    Our facilities are fully accessible and we welcome visitors of all ages and backgrounds.
    Please get in touch if you'd like to know more about what we do or how you can get involved.
  LOREM_IPSUM

  # Name templates for procedural generation — ward name is prepended
  # Each type has categories (by name) and facilities (by name) to assign
  PARTNER_TYPES = [
    { suffix: 'Food Bank',
      summary: 'Distributing food and essentials to those in need',
      categories: ['Food', 'Community Events'],
      facilities: ['Wheelchair Accessible', 'Parking Available'],
      image: '06_food.jpg',
      is_a_place: true },
    { suffix: 'Yoga Studio',
      summary: 'Yoga and mindfulness classes for all levels',
      categories: ['Health & Wellbeing', 'Sports & Fitness'],
      facilities: ['Wheelchair Accessible'],
      image: '04_sports.jpg' },
    { suffix: 'Community Garden',
      summary: 'Shared growing space and gardening workshops',
      categories: ['Health & Wellbeing', 'Community Events'],
      facilities: ['Parking Available', 'Child Friendly'],
      image: '02_garden.jpg',
      is_a_place: true },
    { suffix: 'Music School',
      summary: 'Music lessons and performance opportunities',
      categories: ['Arts & Culture', 'Education & Learning'],
      facilities: ['Hearing Loop'],
      image: '07_music.jpg' },
    { suffix: 'Repair Cafe',
      summary: 'Free repair sessions to reduce waste',
      categories: ['Community Events'],
      facilities: ['Wheelchair Accessible', 'Child Friendly'],
      image: '10_workshop.jpg' },
    { suffix: 'Cycling Club',
      summary: 'Group rides and cycle maintenance workshops',
      categories: ['Sports & Fitness', 'Health & Wellbeing'],
      facilities: ['Parking Available'],
      image: '04_sports.jpg' },
    { suffix: 'Book Club',
      summary: 'Monthly reading group and literary events',
      categories: ['Education & Learning', 'Arts & Culture'],
      facilities: ['Wheelchair Accessible', 'Hearing Loop'],
      partnerships: ['Normal Island Book Clubs'],
      image: '03_library.jpg' },
    { suffix: 'Craft Workshop',
      summary: 'Hands-on craft sessions for all ages',
      categories: ['Arts & Crafts', 'Community Events'],
      facilities: ['Wheelchair Accessible', 'Child Friendly'],
      image: '05_arts.jpg' },
    { suffix: 'Walking Group',
      summary: 'Guided walks exploring local heritage and nature',
      categories: ['Health & Wellbeing', 'Community Events'],
      facilities: [],
      image: '09_walking.jpg' },
    { suffix: 'Advice Centre',
      summary: 'Free advice on housing, benefits, and debt',
      categories: ['Community Events'],
      facilities: ['Wheelchair Accessible', 'Hearing Loop'],
      image: '01_community.jpg',
      is_a_place: true },
    { suffix: 'Playgroup',
      summary: 'Play sessions for under-5s and their carers',
      categories: ['Children & Family', 'Community Events'],
      facilities: ['Wheelchair Accessible', 'Child Friendly', 'Parking Available'],
      image: '08_children.jpg' },
    { suffix: 'Film Society',
      summary: 'Community cinema screenings and discussions',
      categories: ['Arts & Culture', 'Entertainment'],
      facilities: ['Wheelchair Accessible', 'Hearing Loop'],
      image: '05_arts.jpg' }
  ].freeze

  PARTNER_IMAGES_DIR = Rails.root.join('db/seeds/images/partners')
  PARTNER_IMAGE_FILES = Dir.glob(PARTNER_IMAGES_DIR.join('*.jpg')).sort.freeze

  WARD_KEYS = NormalIsland::WARDS.keys.freeze

  def self.attach_image(partner, image_filename)
    path = PARTNER_IMAGES_DIR.join(image_filename)
    return unless path.exist?

    partner.image = File.open(path)
    partner.save!
  end

  # Deterministic social media handles based on partner name
  def self.slug_for(name)
    name.parameterize.gsub('-', '_')[0..14]
  end

  def self.assign_tags(partner, type)
    %i[categories facilities partnerships].each do |tag_type|
      (type[tag_type] || []).each do |tag_name|
        tag = Tag.find_by(name: tag_name)
        PartnerTag.find_or_create_by!(partner: partner, tag: tag) if tag
      end
    end
  end

  def self.add_metadata(partner, type, ward_name, idx)
    handle = slug_for(partner.name)
    # Generate realistic-looking 0161 (Manchester-style) numbers
    phone_a = format('%03d', ((idx * 7) + 100) % 1000)
    phone_b = format('%04d', ((idx * 13) + 1000) % 10_000)

    partner.update_columns( # rubocop:disable Rails/SkipsModelValidations
      url: "https://#{partner.slug}.example.org",
      twitter_handle: handle,
      instagram_handle: handle,
      facebook_link: handle,
      public_phone: "0161 #{phone_a} #{phone_b}",
      public_email: "hello@#{partner.slug}.example.org",
      public_name: partner.name,
      partner_email: "admin@#{partner.slug}.example.org",
      partner_name: "#{ward_name} Admin",
      partner_phone: "0161 #{phone_a} #{phone_b.reverse}",
      opening_times: [
        { 'dayOfWeek' => 'https://schema.org/Monday', 'opens' => '09:00', 'closes' => '17:00' },
        { 'dayOfWeek' => 'https://schema.org/Tuesday', 'opens' => '09:00', 'closes' => '17:00' },
        { 'dayOfWeek' => 'https://schema.org/Wednesday', 'opens' => '09:00', 'closes' => '17:00' },
        { 'dayOfWeek' => 'https://schema.org/Thursday', 'opens' => '09:00', 'closes' => '17:00' },
        { 'dayOfWeek' => 'https://schema.org/Friday', 'opens' => '09:00', 'closes' => '17:00' },
        { 'dayOfWeek' => 'https://schema.org/Saturday', 'opens' => '10:00', 'closes' => '14:00' }
      ].to_json,
      accessibility_info: type[:is_a_place] ? 'Step-free access throughout. Accessible toilets on ground floor.' : nil,
      is_a_place: type[:is_a_place] || false
    )
  end

  def self.run
    $stdout.puts 'Partners'

    # 1. Create the 6 named partners from NormalIsland::PARTNERS
    named_type = {
      categories: ['Community Events'],
      facilities: ['Wheelchair Accessible'],
      is_a_place: true
    }

    NormalIsland::PARTNERS.each_with_index do |(_key, data), idx|
      next if Partner.exists?(name: data[:name])

      ward_data = NormalIsland::WARDS[data[:ward]]
      ward = Neighbourhood.find_by(unit_code_value: ward_data[:unit_code_value])
      next unless ward

      address_data = NormalIsland::ADDRESSES[data[:ward]]

      address = Address.create!(
        street_address: address_data[:street_address],
        postcode: address_data[:postcode],
        latitude: address_data[:latitude],
        longitude: address_data[:longitude],
        neighbourhood: ward
      )

      partner = Partner.create!(
        name: data[:name],
        summary: data[:summary],
        description: LONG_TEXT,
        address: address
      )

      assign_tags(partner, named_type)
      add_metadata(partner, named_type, ward_data[:name], idx)
      attach_image(partner, File.basename(PARTNER_IMAGE_FILES[idx % PARTNER_IMAGE_FILES.length]))
      $stdout.puts "  Created partner: #{partner.name} (#{ward.name})"
    end

    # 2. Generate ~96 more partners, distributed across all 8 wards (12 each)
    partner_number = 0
    WARD_KEYS.each do |ward_key|
      ward_data = NormalIsland::WARDS[ward_key]
      ward = Neighbourhood.find_by(unit_code_value: ward_data[:unit_code_value])
      next unless ward

      address_data = NormalIsland::ADDRESSES[ward_key]
      ward_name = ward_data[:name]

      PARTNER_TYPES.each_with_index do |type, idx|
        partner_number += 1
        name = "#{ward_name} #{type[:suffix]}"
        next if Partner.exists?(name: name)

        address = Address.create!(
          street_address: "#{partner_number} #{ward_name} Street",
          postcode: address_data[:postcode],
          latitude: address_data[:latitude] + (idx * 0.001),
          longitude: address_data[:longitude] + (idx * 0.001),
          neighbourhood: ward
        )

        partner = Partner.create!(
          name: name,
          summary: "#{type[:summary]} in #{ward_name}",
          description: LONG_TEXT,
          address: address
        )

        assign_tags(partner, type)
        add_metadata(partner, type, ward_name, partner_number)
        attach_image(partner, type[:image])
        $stdout.puts "  Created partner: #{partner.name} (#{ward.name})"
      end
    end

    $stdout.puts "  Total partners: #{Partner.count}"
  end
end

SeedPartners.run
