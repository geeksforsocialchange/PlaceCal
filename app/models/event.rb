# frozen_string_literal: true

# app/models/event.rb
class Event < ApplicationRecord
  has_paper_trail ignore: %i[rrule notices]

  belongs_to :partner, optional: true
  belongs_to :place, class_name: 'Partner', optional: true
  belongs_to :address, optional: true
  belongs_to :calendar, optional: true
  has_and_belongs_to_many :collections

  validates :summary, :dtstart, presence: true
  before_validation :set_address_from_place
  validate :require_location

  before_save :sanitize_rrule

  # has_many :service_areas, through: :partner

  # Find by day
  scope :find_by_day, lambda { |day|
    where('dtstart >= ? AND dtstart <= ?', day.midnight, day.midnight + 1.day)
  }

  # Find by week
  scope :find_by_week, lambda { |day|
    week_start = day.beginning_of_week
    week_end = day.end_of_week 
    where('DATE(dtstart) >= ? AND DATE(dtstart) <= ?', week_start, week_end)
  }

  # Filter by Site
  scope :for_site, lambda { |site|
    site_neighbourhood_ids = site.owned_neighbourhoods.map(&:id)

    joins(:address)
      .joins('left join partners on events.partner_id = partners.id')
      .joins('left join service_areas on partners.id = service_areas.partner_id')
      .where('(service_areas.neighbourhood_id in (?)) or (addresses.neighbourhood_id in (?))', site_neighbourhood_ids, site_neighbourhood_ids)
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

  scope :upcoming, ->() { where('dtstart >= ?', DateTime.current.beginning_of_day) }

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

  def permalink
    "https://placecal.org/events/#{id}"
  end

  def neighbourhood
    address&.neighbourhood
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

  # Make sure that setting the event's Place also sets the event's Address. This
  # way we never need to choose between Event#address and Event#place.address
  # This is particularly important for joins for neighbourhoods.
  def set_address_from_place
    self.address_id = self.place.address_id if self.place_id
  end

  def require_location
    return unless self.address_id.blank?
    errors.add(:base, "No place or address could be created or found for
                       the event location: #{raw_location_from_source}")
  end
end
