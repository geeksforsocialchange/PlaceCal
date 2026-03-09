# frozen_string_literal: true

# app/models/event.rb
class Event < ApplicationRecord
  has_paper_trail ignore: %i[rrule notices]

  include HtmlRenderCache

  html_render_cache :description
  html_render_cache :summary

  belongs_to :organiser, class_name: 'Partner', optional: true
  belongs_to :place, class_name: 'Partner', optional: true
  belongs_to :address, optional: true
  belongs_to :online_address, optional: true
  belongs_to :calendar, optional: true
  has_and_belongs_to_many :collections

  validates :summary, :dtstart, :organiser, presence: true
  validate :require_location
  validate :unique_event, on: :create # If we are updating the event we don't want it to trigger!

  before_save :sanitize_rrule

  # has_many :service_areas, through: :partner

  # Find events that start on a given day
  scope :find_by_day, lambda { |day|
    where('DATE(dtstart) = ?', day.to_date)
  }

  # Find by week (Monday to Sunday)
  scope :find_by_week, lambda { |day|
    week_start = day.beginning_of_week
    week_end = day.end_of_week
    where('(DATE(dtstart) >= (?)) AND (DATE(dtstart) <= (?))', week_start, week_end)
  }

  # Find next 7 days from given day
  scope :find_next_7_days, lambda { |day|
    day_start = day.to_date
    day_end = day_start + 6.days
    where('(DATE(dtstart) >= (?)) AND (DATE(dtstart) <= (?))', day_start, day_end)
  }

  # Find by day onwards
  scope :future, lambda { |day|
    day_start = day.midnight # 2024-04-01 00:00:00 +0100
    where(dtstart: day_start..)
  }

  # For the API eventFilter find by neighbourhood
  scope :for_neighbourhoods, lambda { |neighbourhoods|
    neighbourhood_ids = neighbourhoods.map(&:id)

    joins('left outer join partners on events.organiser_id = partners.id')
      .joins('left outer join addresses on partners.address_id = addresses.id')
      .joins('left outer join service_areas on partners.id = service_areas.partner_id')
      .where('(service_areas.neighbourhood_id in (?)) or (addresses.neighbourhood_id in (?))',
             neighbourhood_ids,
             neighbourhood_ids)
  }

  scope :with_tags, lambda { |tags|
    joins(:organiser)
      .joins('left outer join partner_tags on partners.id = partner_tags.partner_id')
      .where(
        'partner_tags.tag_id in (:tag_ids)',
        tag_ids: tags.map(&:id)
      )
  }

  # Filter by Place
  scope :in_place, ->(place) { where(place: place) }

  # Filter by Organiser
  scope :by_organiser, ->(organiser) { where(organiser: organiser) }

  # Filter by Organiser or Place
  scope :by_organiser_or_place, ->(organiser) { in_place(organiser).or(by_organiser(organiser)) }

  # Sort by Summary or Start Time
  scope :sort_by_summary, -> { order(summary: :asc).order(:dtstart) }
  scope :sort_by_time, -> { order(dtstart: :asc).order(summary: :asc) }

  scope :without_matching_times, lambda { |time_pairs|
    return none if time_pairs.empty?

    conditions = time_pairs.map { |s, e| arel_table[:dtstart].eq(s).and(arel_table[:dtend].eq(e)) }
    matching = conditions.reduce(:or)
    where.not(matching)
  }

  # Only events that don't repeat
  scope :one_off_events_only, -> { where(rrule: false) }
  scope :one_off_events_first, -> { order(rrule: :asc) }

  scope :upcoming, -> { where(dtstart: DateTime.current.beginning_of_day..) }
  scope :past, -> { where(dtstart: ..DateTime.current.beginning_of_day) }

  # Global feed
  scope :ical_feed, -> { where(dtstart: (Time.now - 1.week)..).where(dtend: ...(Time.now + 2.years)) }

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
    use_address = address || partner_at_location&.address || organiser&.address
    return '' if use_address.nil?

    use_address.to_s
  end

  def partner_at_location
    @partner_at_location ||= place || Partner.find_from_event_address(address)
  end

  # TODO: plan this out on paper, currently half finished
  # Who to contact if the event is wrong
  def blame
    organiser = calendar&.organiser
    return false unless organiser

    email = organiser.admin_email
    name = organiser.admin_name
    "Something wrong with this listing? Contact #{name} <#{email}> with reference {url}"
  end

  def og_title
    str = "#{summary}, #{date}, #{time}"
    str += " @ #{organiser.name}" if organiser
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
                       .any?

    errors.add(:base, 'Unfortunately this event is a duplicate of an ' \
                      "existing event for calendar: #{calendar_id} " \
                      "('#{calendar.name}')")
  end
end
