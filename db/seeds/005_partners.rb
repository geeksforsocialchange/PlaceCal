# frozen_string_literal: true

require_relative '../../lib/normal_island'

module SeedPartners # rubocop:disable Metrics/ModuleLength
  # The old placeholder description; a re-run refreshes partners that still carry it.
  LEGACY_DESCRIPTION = <<~LOREM_IPSUM
    Welcome to our community organisation! We provide a range of services and activities
    for local residents. Our friendly team is dedicated to supporting the community and
    creating opportunities for everyone to get involved.

    We offer regular events, workshops, and drop-in sessions throughout the week. Whether
    you're looking for social activities, learning opportunities, or just a friendly place
    to meet others, we're here for you.

    Our facilities are fully accessible and we welcome visitors of all ages and backgrounds.
    Please get in touch if you'd like to know more about what we do or how you can get involved.
  LOREM_IPSUM

  # Copy for the named partners in NormalIsland::PARTNERS, keyed by name.
  NAMED_COPY = {
    'Riverside Community Hub' => {
      summary: 'A community centre by the river in Riverside, with a cafe, meeting rooms and a full week of groups run by and for local people.',
      description: [
        'The hub is open seven days a week. Our noticeboard and website list every group that meets here, from coffee mornings to coding clubs.',
        'Rooms can be booked at low cost by any community group, and the cafe runs a pay-it-forward board for anyone who needs a meal.'
      ]
    },
    'Oldtown Library' => {
      summary: 'A Victorian library in Oldtown with free computers and wifi, study space, and a busy programme of talks and story times.',
      description: [
        'Library staff can help you get online, print documents and find information about local services.',
        'There are quiet study tables upstairs, a children\'s corner downstairs, and a free room for community groups on weekday evenings.'
      ]
    },
    'Greenfield Youth Centre' => {
      summary: 'A youth centre in Greenfield for 11 to 25 year olds, with evening sessions, a games room, mentoring and a quiet space to talk.',
      description: [
        'Youth workers are around every evening and can help with school, work, money and anything else on your mind.',
        'There is a weekly group for LGBTQ+ young people, and every session is free.'
      ]
    },
    'Harbourside Arts Centre' => {
      summary: 'An arts centre on the harbour with a gallery, a small theatre and studio spaces. Workshops and exhibitions put local artists first.',
      description: [
        'The gallery is free to visit, and the theatre runs relaxed performances for anyone who finds a busy auditorium hard.',
        'Studio spaces are let at low rents to local artists, and open studio weekends happen twice a year.'
      ]
    },
    'Ashdale Sports Club' => {
      summary: 'A sports club in Ashdale with football, netball and swimming sessions, and changing facilities that work for everyone.',
      description: [
        'Teams train in the evenings and play at weekends, and there are beginner sessions for adults who have never played before.',
        'The club has private changing cubicles and a clear policy welcoming players of every gender.'
      ]
    },
    'Coastline Wellness Centre' => {
      summary: 'A seafront wellness centre in Cliffside offering counselling, massage and peer support groups, with low-cost sessions available.',
      description: [
        'Counsellors offer short and longer-term support in person or by video call, with fees based on what you can afford.',
        'Peer support groups meet weekly, including groups for carers, for people living with long-term pain, and for anyone feeling isolated.'
      ]
    }
  }.freeze

  # Name templates for procedural generation — ward name is prepended
  # Each type has categories (by name) and facilities (by name) to assign
  PARTNER_TYPES = [
    { suffix: 'Food Bank',
      summaries: [
        'A volunteer-run food bank in %s handing out food parcels, toiletries and baby supplies. No referral is needed for your first visit.',
        'Free food parcels and essentials for anyone in %s who is struggling. Come along to a drop-in and we will not ask you to explain yourself.'
      ],
      description: [
        'We open three mornings a week from the hall on our street and run a delivery round for people who cannot get to us.',
        'Everything we hand out is donated by neighbours, local shops and the supermarket on the high street. If you can spare an hour, we always need volunteers to sort and pack.'
      ],
      categories: ['Food', 'Community Events'],
      facilities: ['Wheelchair Accessible', 'Parking Available'],
      image: '06_food.jpg',
      is_a_place: true },
    { suffix: 'Yoga Studio',
      summaries: [
        'Gentle and flowing yoga classes in %s for every body and every level, with mats and props provided.',
        'Small, friendly yoga and breathwork classes in %s. Beginners are always welcome and pay-what-you-can places are held at every session.'
      ],
      description: [
        'Classes run on weekday evenings and Saturday mornings, and every pose has a seated or supported option.',
        'Our teachers keep groups small so they can learn your name and what your body needs. Tell us about injuries or access needs and we will plan around them.'
      ],
      categories: ['Health & Wellbeing', 'Sports & Fitness'],
      facilities: ['Wheelchair Accessible'],
      image: '04_sports.jpg' },
    { suffix: 'Community Garden',
      summaries: [
        'A shared growing space in %s where neighbours grow vegetables, swap seeds and learn gardening together.',
        'Volunteer gardening sessions every week in %s. No experience needed, just turn up in clothes you do not mind getting muddy.'
      ],
      description: [
        'The garden has raised beds, a polytunnel, a pond and a covered seating area for when it rains.',
        'Volunteers share whatever we grow, and the rest goes to the food bank down the road. Tools, gloves and tea are provided.'
      ],
      categories: ['Health & Wellbeing', 'Community Events'],
      facilities: ['Parking Available', 'Child Friendly'],
      image: '02_garden.jpg',
      is_a_place: true },
    { suffix: 'Music School',
      summaries: [
        'Affordable music lessons in %s for children and adults, from first notes on guitar and piano to playing in a band.',
        'A community music school in %s running lessons, choirs and open mic nights. Instruments can be borrowed for free.'
      ],
      description: [
        'Lessons are one to one or in small groups, and fees are on a sliding scale so cost is never the reason someone stops playing.',
        'Every term ends with a concert where students of every age and ability perform together.'
      ],
      categories: ['Arts & Culture', 'Education & Learning'],
      facilities: ['Hearing Loop'],
      image: '07_music.jpg' },
    { suffix: 'Repair Cafe',
      summaries: [
        'Bring your broken toasters, bikes and torn clothes to our monthly repair cafe in %s and fix them with a volunteer.',
        'Free repair sessions in %s that keep things out of landfill. Tea, cake and a friendly fixer for whatever you bring.'
      ],
      description: [
        'Our volunteers include electricians, tailors and bike mechanics, and they will show you how to do the repair yourself if you want to learn.',
        'Sessions are on the first Saturday of the month. Repairs are free, and donations towards spare parts are welcome.'
      ],
      categories: ['Community Events'],
      facilities: ['Wheelchair Accessible', 'Child Friendly'],
      image: '10_workshop.jpg' },
    { suffix: 'Cycling Club',
      summaries: [
        'Relaxed group rides around %s at a no-drop pace, plus monthly workshops on keeping your bike roadworthy.',
        'A friendly cycling club in %s for riders of all speeds. Loan bikes are available if you do not have your own yet.'
      ],
      description: [
        'Rides go out on Sunday mornings and one weekday evening, with a short route and a longer route each time.',
        'Nobody gets left behind: a ride leader stays at the back of every group. Helmets and lights can be borrowed.'
      ],
      categories: ['Sports & Fitness', 'Health & Wellbeing'],
      facilities: ['Parking Available'],
      image: '04_sports.jpg' },
    { suffix: 'Book Club',
      summaries: [
        'A monthly reading group in %s that meets over tea to talk about novels, memoirs and poetry. Newcomers welcome any month.',
        'Readers in %s who meet once a month to share a book and a conversation. Copies are available to borrow from the group.'
      ],
      description: [
        'We take turns choosing the book, and it is fine to come along even if you did not finish it.',
        'Meetings are on the last Thursday of the month in a quiet room with step-free access. Large print and audio copies are available on request.'
      ],
      categories: ['Education & Learning', 'Arts & Culture'],
      facilities: ['Wheelchair Accessible', 'Hearing Loop'],
      partnerships: ['Normal Island Book Clubs'],
      image: '03_library.jpg' },
    { suffix: 'Craft Workshop',
      summaries: [
        'Hands-on craft sessions in %s covering knitting, printmaking, sewing and more, with all materials supplied.',
        'A relaxed weekly craft group in %s. Bring a project or start a new one, and pick up skills from the people around you.'
      ],
      description: [
        'Each month has a theme, from lino printing to visible mending, led by a local maker.',
        'Sessions are low cost and nobody is turned away for lack of funds. Children are welcome with an adult.'
      ],
      categories: ['Arts & Crafts', 'Community Events'],
      facilities: ['Wheelchair Accessible', 'Child Friendly'],
      image: '05_arts.jpg' },
    { suffix: 'Walking Group',
      summaries: [
        'Free guided walks around %s exploring local history, parks and green spaces at an easy pace.',
        'A weekly walking group in %s for anyone who wants fresh air and company. Routes are short, flat and step-free where possible.'
      ],
      description: [
        'Walks last about an hour and finish at a cafe for anyone who wants to stay and chat.',
        'Our walk leaders are trained volunteers who know the area well. Dogs on leads and buggies are welcome.'
      ],
      categories: ['Health & Wellbeing', 'Community Events'],
      facilities: [],
      image: '09_walking.jpg' },
    { suffix: 'Advice Centre',
      summaries: [
        'Free, confidential advice in %s on housing, benefits, debt and work, from trained advisers who will take your side.',
        'Drop in to the %s advice centre for help with forms, appeals and money worries. Interpreters can be booked in advance.'
      ],
      description: [
        'You can drop in on weekday mornings or book an appointment by phone. Home visits are available if you cannot get to us.',
        'Advisers can help you fill in forms, write letters and go with you to tribunals. Everything you tell us stays between you and your adviser.'
      ],
      categories: ['Community Events'],
      facilities: ['Wheelchair Accessible', 'Hearing Loop'],
      image: '01_community.jpg',
      is_a_place: true },
    { suffix: 'Playgroup',
      summaries: [
        'Play sessions in %s for under-fives and the grown-ups who look after them, with toys, songs and a hot drink.',
        'A welcoming parent and carer playgroup in %s. Every kind of family is welcome, and the first session is free.'
      ],
      description: [
        'Sessions run on weekday mornings with messy play, a story and a singing circle.',
        'It is a good place to meet other parents and carers nearby. There is a quiet corner for feeding and baby changing on site.'
      ],
      categories: ['Children & Family', 'Community Events'],
      facilities: ['Wheelchair Accessible', 'Child Friendly', 'Parking Available'],
      image: '08_children.jpg' },
    { suffix: 'Film Society',
      summaries: [
        'Community cinema in %s showing independent and classic films once a fortnight, followed by an informal chat.',
        'A volunteer-run film club in %s with subtitled screenings, cheap tickets and a bar that serves tea as well as wine.'
      ],
      description: [
        'Members vote on the programme each season, and every screening has captions.',
        'Tickets are kept cheap and members get a discount. Doors open half an hour before the film for anyone who wants to talk.'
      ],
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

  def self.paragraphs(list, ward_name = nil)
    list.map { |text| ward_name ? format(text, ward_name) : text }.join("\n\n")
  end

  # True when the partner exists; its copy is refreshed only while it still has the placeholder.
  def self.already_seeded?(name, summary, description)
    partner = Partner.find_by(name: name)
    return false unless partner

    if partner.description == LEGACY_DESCRIPTION
      partner.assign_attributes(summary: summary, description: description)
      # Copy only: other dev edits (such as a removed address) must not block the refresh.
      partner.save!(validate: false)
      $stdout.puts "  Refreshed copy: #{partner.name}"
    end
    true
  end

  def self.run
    $stdout.puts 'Partners'
    seed_named_partners
    seed_generated_partners
    $stdout.puts "  Total partners: #{Partner.count}"
  end

  # 1. Create the 6 named partners from NormalIsland::PARTNERS
  def self.seed_named_partners
    named_type = {
      categories: ['Community Events'],
      facilities: ['Wheelchair Accessible'],
      is_a_place: true
    }

    NormalIsland::PARTNERS.each_with_index do |(_key, data), idx|
      copy = NAMED_COPY.fetch(data[:name])
      summary = copy[:summary]
      description = paragraphs(copy[:description])
      next if already_seeded?(data[:name], summary, description)

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
        summary: summary,
        description: description,
        address: address
      )

      assign_tags(partner, named_type)
      add_metadata(partner, named_type, ward_data[:name], idx)
      attach_image(partner, File.basename(PARTNER_IMAGE_FILES[idx % PARTNER_IMAGE_FILES.length]))
      $stdout.puts "  Created partner: #{partner.name} (#{ward.name})"
    end
  end

  # 2. Generate ~96 more partners, distributed across all 8 wards (12 each)
  def self.seed_generated_partners
    partner_number = 0
    WARD_KEYS.each_with_index do |ward_key, ward_idx|
      ward_data = NormalIsland::WARDS[ward_key]
      ward = Neighbourhood.find_by(unit_code_value: ward_data[:unit_code_value])
      next unless ward

      address_data = NormalIsland::ADDRESSES[ward_key]
      ward_name = ward_data[:name]

      PARTNER_TYPES.each_with_index do |type, idx|
        partner_number += 1
        name = "#{ward_name} #{type[:suffix]}"
        summary = format(type[:summaries][ward_idx % type[:summaries].length], ward_name)
        description = paragraphs(type[:description], ward_name)
        next if already_seeded?(name, summary, description)

        address = Address.create!(
          street_address: "#{partner_number} #{ward_name} Street",
          postcode: address_data[:postcode],
          latitude: address_data[:latitude] + (idx * 0.001),
          longitude: address_data[:longitude] + (idx * 0.001),
          neighbourhood: ward
        )

        partner = Partner.create!(
          name: name,
          summary: summary,
          description: description,
          address: address
        )

        assign_tags(partner, type)
        add_metadata(partner, type, ward_name, partner_number)
        attach_image(partner, type[:image])
        $stdout.puts "  Created partner: #{partner.name} (#{ward.name})"
      end
    end
  end
end

SeedPartners.run

# Assign admin associations to users now that partners, sites, and neighbourhoods exist
$stdout.puts 'User associations'
SeedUsers.assign_associations
