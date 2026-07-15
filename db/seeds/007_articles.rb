# frozen_string_literal: true

# News articles for a sample of partners (issue #3308). Millbrook and Ashdale
# partners get news so their sites show the News tab, partner-page sections,
# and populated feeds; Seaview/Coastshire is deliberately left without any so
# the no-news state (no nav tab) stays demonstrable.
module SeedArticles # rubocop:disable Metrics/ModuleLength
  # One template per partner-type suffix, matched against the procedurally
  # generated partner names from 005_partners.rb
  TEMPLATES = {
    'Food Bank' => {
      title: 'Winter opening hours and how you can help',
      body: <<~MARKDOWN
        We're extending our opening hours over the winter months so nobody has to
        choose between warmth and food.

        ## New opening times

        - **Monday to Friday**: 9am – 5pm
        - **Saturday**: 10am – 2pm

        We always need tinned goods, UHT milk and toiletries. Drop donations in
        during opening hours — and thank you, as ever, for your support.
      MARKDOWN
    },
    'Community Garden' => {
      title: 'Spring planting day — everyone welcome',
      body: <<~MARKDOWN
        Our annual **spring planting day** is coming up and we'd love to see you
        there. No experience needed — tools, gloves and tea provided.

        ## What we're planting

        - Raised beds of salad and herbs
        - A new wildflower border for the pollinators
        - Fruit trees along the back fence

        Bring sturdy shoes and a friend. Kids very welcome.
      MARKDOWN
    },
    'Repair Cafe' => {
      title: 'A record month of repairs',
      body: <<~MARKDOWN
        Last month our volunteers fixed **47 items** that would otherwise have
        gone to landfill — toasters, trousers, laptops and one much-loved teddy
        bear.

        If you have something broken, bring it along to our next session. If you
        can solder, sew or just make good tea, we'd love your help too.
      MARKDOWN
    },
    'Music School' => {
      title: 'Free taster lessons this term',
      body: <<~MARKDOWN
        We have a handful of **free taster lessons** available this term for
        anyone who's always fancied picking up an instrument.

        Guitar, keyboard, voice and drums — all ages, all levels, no sheet music
        required. Get in touch to book a slot.
      MARKDOWN
    },
    'Yoga Studio' => {
      title: 'New beginners class on Saturday mornings',
      body: <<~MARKDOWN
        By popular demand we're adding a **beginners class** on Saturday
        mornings. Slow-paced, friendly, and no bendiness required.

        Mats provided. Wear something comfortable and arrive ten minutes early
        for your first session.
      MARKDOWN
    },
    'Cycling Club' => {
      title: 'Group rides restart next week',
      body: <<~MARKDOWN
        The evenings are getting lighter, which means our **group rides** are
        back on. All abilities welcome — nobody gets dropped.

        ## The plan

        - Tuesdays: gentle social ride, about an hour
        - Sundays: longer route with a cafe stop

        Free bike checks before every ride from our maintenance volunteers.
      MARKDOWN
    }
  }.freeze

  DISTRICTS_WITH_NEWS = %w[Millbrook Ashdale].freeze

  def self.run
    $stdout.puts 'Articles'

    author = User.find_by(email: 'editor@placecal.org') || User.find_by(role: 'root')
    unless author
      $stdout.puts '  Skipping: no editor or root user to author articles'
      return
    end

    create_partner_articles(author)
    create_joint_article(author)
    create_draft_article(author)

    $stdout.puts "  Total articles: #{Article.count}"
  end

  # Spread publication dates over recent weeks, so every list and feed has a
  # meaningful order
  def self.create_partner_articles(author)
    newsworthy_partners.each_with_index do |(partner, template), index|
      title = "#{template[:title]} — #{partner.name}"
      next if Article.exists?(title: title)

      article = Article.create!(
        title: title,
        body: template[:body],
        author: author,
        is_draft: false,
        published_at: (index + 1).weeks.ago.change(hour: 9 + (index % 8)),
        partners: [partner]
      )
      attach_image(article, partner)
      $stdout.puts "  Created article: #{article.title}"
    end
  end

  # A joint post between two partners, to exercise multi-partner display and
  # the distinct handling in Article.for_site
  def self.create_joint_article(author)
    partners = Partner.where("name LIKE 'Riverside %'").order(:name).limit(2).to_a
    return if partners.size < 2

    title = 'Riverside Summer Fair — a joint announcement'
    return if Article.exists?(title: title)

    Article.create!(
      title: title,
      body: <<~MARKDOWN,
        Two of Riverside's community organisations are teaming up for a
        **summer fair** on the green — stalls, food, music and activities for
        all ages.

        Want a stall? Get in touch with either of us. All proceeds go back into
        running free sessions through the year.
      MARKDOWN
      author: author,
      is_draft: false,
      published_at: 2.days.ago.change(hour: 14),
      partners: partners
    )
    $stdout.puts "  Created article: #{title}"
  end

  def self.create_draft_article(author)
    partner, = newsworthy_partners.first
    return unless partner

    title = 'Draft: our plans for next year'
    return if Article.exists?(title: title)

    Article.create!(
      title: title,
      body: "Still being written — this draft is only visible in the admin.\n",
      author: author,
      is_draft: true,
      partners: [partner]
    )
    $stdout.puts "  Created draft: #{title}"
  end

  # Two [partner, template] pairs per ward in the districts that get news,
  # rotating through the templates so wards don't all publish the same thing
  def self.newsworthy_partners
    @newsworthy_partners ||= newsworthy_wards.each_with_index.flat_map do |ward, index|
      TEMPLATES.keys.rotate(index).take(2).filter_map do |suffix|
        partner = Partner.find_by(name: "#{ward[:name]} #{suffix}")
        [partner, TEMPLATES[suffix]] if partner
      end
    end
  end

  def self.newsworthy_wards
    NormalIsland::WARDS.filter_map do |_key, ward|
      ward if DISTRICTS_WITH_NEWS.include?(NormalIsland::DISTRICTS[ward[:parent_district]][:name])
    end
  end

  def self.attach_image(article, partner)
    return unless partner.image.present? && partner.image.file&.exists?

    article.article_image = File.open(partner.image.file.path)
    article.save!
  rescue StandardError => e
    $stdout.puts "  (no image for #{article.title}: #{e.message})"
  end
end

SeedArticles.run
