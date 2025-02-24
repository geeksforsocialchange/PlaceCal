# frozen_string_literal: true

# app/models/event.rb
class Event < ApplicationRecord
  has_paper_trail ignore: %i[rrule notices]

  include HtmlRenderCache
  html_render_cache :description
  html_render_cache :summary

  belongs_to :partner, optional: true
  belongs_to :place, class_name: 'Partner', optional: true
  belongs_to :address, optional: true
  belongs_to :online_address, optional: true
  belongs_to :calendar, optional: true
  has_and_belongs_to_many :collections

  validates :summary, :dtstart, :partner, presence: true
  validate :require_location
  validate :unique_event, on: :create # If we are updating the event we don't want it to trigger!

  before_save :sanitize_rrule

  # has_many :service_areas, through: :partner

  # Find by day
  scope :find_by_day, lambda { |day|
    # This is simple single-axis bounding box collision logic :)
    # the x+w is event_end/day_end and the x is event_start/day_start
    # day_end >= event_start AND day_start <= event_end
    day_start = day.midnight
    day_end = (day.midnight + 1.day)
    where('((?) >= dtstart AND ((?) <= dtend))',
          day_end, day_start)
  }

  # Find by week
  scope :find_by_week, lambda { |day|
    week_start = day.beginning_of_week
    week_end = day.end_of_week
    where('(DATE(dtstart) >= (?)) AND (DATE(dtstart) <= (?))', week_start, week_end)
  }

  # Find by day onwards
  scope :future, lambda { |day|
    day_start = day.midnight # 2024-04-01 00:00:00 +0100
    where(dtstart: day_start..)
  }

  # For the API eventFilter find by neighbourhood
  scope :for_neighbourhoods, lambda { |neighbourhoods|
    neighbourhood_ids = neighbourhoods.map(&:id)

    joins('left outer join partners on events.partner_id = partners.id')
      .joins('left outer join addresses on partners.address_id = addresses.id')
      .joins('left outer join service_areas on partners.id = service_areas.partner_id')
      .where('(service_areas.neighbourhood_id in (?)) or (addresses.neighbourhood_id in (?))',
             neighbourhood_ids,
             neighbourhood_ids)
  }

  scope :with_tags, lambda { |tags|
    joins(:partner)
      .joins('left outer join partner_tags on partners.id = partner_tags.partner_id')
      .where(
        'partner_tags.tag_id in (:tag_ids)',
        tag_ids: tags.map(&:id)
      )
  }

  # Filter by Site
  scope :for_site, lambda { |site|
    partners = Partner.for_site(site)

    if site&.tags&.any?
      left_joins(:address)
        .where(
          'partner_id in (:partner_ids) OR '\
          '(lower(addresses.street_address) in (:partner_names) AND '\
          'lower(addresses.postcode) in (:partner_postcodes))',
          partner_ids: partners.map(&:id),
          partner_names: partners.map { |p| p.name.downcase },
          partner_postcodes: partners.map(&:address).compact_blank!.map { |a| a.postcode.downcase }
        )
    else
      left_joins(:address)
        .where(
          'partner_id in (:partner_ids) OR '\
          'addresses.neighbourhood_id in (:neighbourhoods)',
          neighbourhoods: site.owned_neighbourhoods.map(&:id),
          partner_ids: partners.map(&:id)
        )
    end
  }

  # Filter by Place
  scope :in_place, ->(place) { where(place: place) }

  # Filter by Partner
  scope :by_partner, ->(partner) { where(partner: partner) }

  # Filter by Partner or Place
  scope :by_partner_or_place, ->(partner) { in_place(partner).or(by_partner(partner)) }

  # Sort by Summary or Start Time
  scope :sort_by_summary, -> { order(summary: :asc).order(:dtstart) }
  scope :sort_by_time, -> { order(dtstart: :asc).order(summary: :asc) }

  scope :without_matching_times, lambda { |start_times, end_times|
    where.not(dtstart: start_times).or(where.not(dtend: end_times))
  }

  # Only events that don't repeat
  scope :one_off_events_only, -> { where(rrule: false) }
  scope :one_off_events_first, -> { order(rrule: :asc) }

  scope :upcoming, -> { where(dtstart: DateTime.current.beginning_of_day..) }
  scope :past, -> { where(dtstart: ..DateTime.current.beginning_of_day) }

  # Global feed
  scope :ical_feed, -> { where(dtstart: (Time.now - 1.week)..).where(dtend: ...(Time.now + 1.month)) }

  def repeat_frequency
    rrule[0]['table']['frequency'].titleize if rrule
  end

  def sanitize_rrule
    self.rrule = false if rrule.nil? || rrule == []
  end

  def time
    if dtend
      "#{dtstart.strftime('%H:%M')} – #{dtend.strftime('%H:%M')}"
    else
      dtstart.strftime('%H:%M')
    end
  end

  def duration
    return false unless dtend

    (dtend - dtstart).seconds.iso8601
  end

  def date
    dtstart.strftime('%e %b')
  end

  def date_year
    dtstart.strftime('%e %b %Y')
  end

  def permalink
    "https://placecal.org/events/#{id}"
  end

  def neighbourhood
    address&.neighbourhood
  end

  def location
    use_address = address || partner_at_location&.address || partner&.address
    return '' if use_address.nil?

    use_address.to_s
  end

  def partner_at_location
    @partner_at_location ||= place || Partner.find_from_event_address(address)
  end

  # TODO: plan this out on paper, currently half finished
  # Who to contact if the event is wrong
  def blame
    partner = calendar&.partner
    return false unless partner

    email = partner.admin_email
    name = partner.admin_name
    "Something wrong with this listing? Contact #{name} <#{email}> with reference {url}"
  end

  def og_title
    str = "#{summary}, #{date}, #{time}"
    str += " @ #{partner.name}" if partner
  end

  private

  def require_location
    # 'event', 'no_location', and 'online_only' do not require a Location
    return if %w[event no_location online_only].include?(calendar&.strategy)

    # If we have an online address we don't need a physical one
    return if online_address_id.present?

    # If the address exists then the error doesn't apply
    return if address_id.present?

    errors.add(:base, 'No place or address could be created or found for ' \
                      "the event location: #{raw_location_from_source}")
  end

  # Ensures that the event added is unique
  # Checks for a duplicate event with the properties dtstart, summary, and calendar_id
  def unique_event
    return unless Event.where(uid: uid,
                              dtstart: dtstart,
                              summary: summary,
                              calendar_id: calendar_id)
                       .count
                       .positive?

    errors.add(:base, 'Unfortunately this event is a duplicate of an ' \
                      "existing event for calendar: #{calendar_id} " \
                      "('#{calendar.name}')")
  end
end
