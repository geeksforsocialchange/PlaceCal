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
    where('(dtstart >= (?)) AND (dtstart <= (?))', day.midnight, (day.midnight + 1.day))
  }

  # Find by week
  scope :find_by_week, lambda { |day|
    week_start = day.beginning_of_week
    week_end = day.end_of_week
    where('(DATE(dtstart) >= (?)) AND (DATE(dtstart) <= (?))', week_start, week_end)
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
    tag_ids = tags.map(&:id)

    joins(:partner)
      .joins('left outer join partner_tags on partners.id = partner_tags.partner_id')
      .where('partner_tags.tag_id in (?)', tag_ids)
  }

  # Filter by Site
  scope :for_site, lambda { |site|
    site_neighbourhood_ids = site.owned_neighbourhoods.map(&:id)

    joins('left join addresses on events.address_id = addresses.id')
      .joins('left join partners on events.partner_id = partners.id')
      .joins('left join service_areas on partners.id = service_areas.partner_id')
      .where('(service_areas.neighbourhood_id in (?)) or (addresses.neighbourhood_id in (?))',
             site_neighbourhood_ids,
             site_neighbourhood_ids)
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

  scope :without_matching_times, ->(start_times, end_times) {
    where.not(dtstart: start_times).or(where.not(dtend: end_times))
  }

  # Only events that don't repeat
  scope :one_off_events_only, -> { where(rrule: false) }
  scope :one_off_events_first, -> { order(rrule: :asc) }

  scope :upcoming, -> { where('dtstart >= ?', DateTime.current.beginning_of_day) }
  scope :past, -> { where('dtstart <= ?', DateTime.current.beginning_of_day) }

  # Global feed
  scope :ical_feed, -> { where('dtstart >= ?', Time.now - 1.week).where('dtend < ?', Time.now + 1.month) }

  def repeat_frequency
    rrule[0]['table']['frequency'].titleize if rrule
  end

  def sanitize_rrule
    self.rrule = false if rrule.nil? || rrule == []
  end

  def time
    if dtend
      dtstart.strftime('%H:%M') + ' – ' + dtend.strftime('%H:%M')
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
    use_address = address || partner&.address
    #  (address if address.present?) ||
    #  (partner.address if partner.present?)

    return '' if use_address.nil?

    use_address.to_s
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

  private

  def require_location
    # 'event', 'no_location', and 'online_only' do not require a Location
    return if %w[event no_location online_only].include?(calendar&.strategy)

    # If we have an online address we don't need a physical one
    return if self.online_address_id.present?

    # If the address exists then the error doesn't apply
    return unless self.address_id.blank?

    errors.add(:base, 'No place or address could be created or found for ' \
                      "the event location: #{raw_location_from_source}")
  end

  # Ensures that the event added is unique
  # Checks for a duplicate event with the properties dtstart, summary, and calendar_id
  def unique_event
    return unless Event.where(dtstart: dtstart,
                              summary: summary,
                              calendar_id: calendar_id)
                       .count
                       .positive?

    errors.add(:base, 'Unfortunately this event is a duplicate of an ' \
                      "existing event for calendar: #{calendar_id} " \
                      "('#{calendar.name}')")
  end
end
