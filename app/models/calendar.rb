# frozen_string_literal: true
# app/models/calendar.rb
class Calendar < ApplicationRecord
  include ActionView::Helpers::DateHelper
  include Validation
  extend Enumerize

  CALENDAR_REGEX = /\A(?:(?:(https?|webcal)):\/\/)(?:\S+(?::\S*)?@)?(?:(?!10(?:\.\d{1,3}){3})(?!127(?:\.\d{1,3}){3})(?!169\.254(?:\.\d{1,3}){2})(?!192\.168(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,})))(?::\d{2,5})?(?:\/[^\s]*)?\z/i

  self.inheritance_column = nil

  belongs_to :partner, optional: true
  belongs_to :place, class_name: 'Partner', optional: true
  has_many :events, dependent: :destroy

  validates :name, :partner, :source, presence: true
  validates :place, presence: { if: :requires_default_location?,
                                message: "can't be blank with this strategy" }
  validates :source, uniqueness: { message: 'calendar source already in use' },
                     format: { with: CALENDAR_REGEX, message: 'not a valid URL' }

  before_save :source_supported

  attribute :is_facebook_page, :boolean, default: false
  attribute :facebook_page_id, :string

  # Defines the strategy this Calendar uses to assign events to locations.
  # @attr [Enumerable<Symbol>] :strategy
  enumerize(
    :strategy,
    in: %i[event place room_number event_override],
    default: :place,
    scope: true
  )

  # We need a default location for some strategies
  def requires_default_location?
    %i[place room_number event_override].include? strategy.to_sym
  end

  # Output constant for event import date limit
  def self.import_up_to
    1.year.from_now
  end

  # Output the calendar's name when it's requested as a string
  def to_s
    name
  end

  # Output recent calendar import activity
  # This uses PaperTrail to get historical records of the Event models, including deletes
  # It does this to show a "event added" / "event removed" thing
  def recent_activity
    versions = PaperTrail::Version.with_item_keys('Event', self.event_ids).where('created_at >= ?', 2.weeks.ago)
    versions = versions.or(PaperTrail::Version.destroys
                                              .where("item_type = 'Event' AND object @> ? AND created_at >= ?",
                                                     { calendar_id: self.id }.to_json, 2.weeks.ago))

    versions = versions.order(created_at: :desc).group_by { |version| version.created_at.to_date }
  end

  def critical_import_failure(error, save_now=true)
    self.critical_error = error
    self.is_working = false
    self.save if save_now
  end

  # Create Events using this Calendar
  # @param from [DateTime]
  def import_events(from)
    return unless place.present? # a quick fix to stop broken code from running

    @notices = []
    @events_uids = []

    parsed_events = events_from_source(from)

    return if parsed_events.events.blank?

    parsed_events.events.each do |event_data|
      occurrences = event_data.occurrences_between(from, Calendar.import_up_to)
      next if event_data.private? || occurrences.blank?

      @events_uids << event_data.uid
      event_data.partner_id = partner_id

      if %w[place room_number].include?(strategy)
        event_data.place_id = place_id

      else
        id_type, id = get_place_or_address(event_data)
        event_data.place_id = id if id_type == :place_id
        event_data.address_id = id if id_type == :address_id
      end

      # Create/Update the new event and update the Calendar import error log (notices) with any errors
      @notices += create_or_update_events(event_data, occurrences, from)
    end

    handle_deleted_events(from, @events_uids) if @events_uids

    reload # reload the record from database to clear out any invalid events to avoid attempts to save them
    begin
      Calendar.record_timestamps = false
      update!( 
        notices: @notices, 
        last_checksum: parsed_events.checksum,
        last_import_at: DateTime.current,
        critical_error: nil
      )

    ensure
      Calendar.record_timestamps = true

    end
  end

  def create_or_update_events(event_data, occurrences, from)
    @important_notices = []
    calendar_events    = events.upcoming.where(uid: event_data.uid)

    # If any dates of this event don't match the imported start times or end times, delete them
    if event_data.recurring_event?
      events_with_invalid_dates = calendar_events.without_matching_times(occurrences.map(&:start_time), occurrences.map(&:end_time))
      events_with_invalid_dates.destroy_all
    end

    occurrences.each do |occurrence|
      # Skip if more than a day apart
      next if occurrence.end_time && (occurrence.end_time.to_date - occurrence.start_time.to_date).to_i > 1
      event_time = { dtstart: occurrence.start_time, dtend: occurrence.end_time }

      event = event_data.recurring_event? ? calendar_events.find_by(event_time) : calendar_events.first if calendar_events.present?
      event = events.new if event.blank?

      event_time[:are_spaces_available] = occurrence.status if occurrence.respond_to?(:status)

      unless event.update event_data.attributes.merge(event_time)
        @important_notices << { event: event, errors: event.errors.full_messages }
      end
    end

    @important_notices
  end

  # Destroys all events in the future if their UID is not included in the input `uids` list
  #
  # == Parameters
  # from::
  #   Unused.
  #
  # uids::
  #   A list of UID strings
  def handle_deleted_events(from, uids)
    upcoming_events = events.upcoming
    deleted_events = upcoming_events.where.not(uid: uids).pluck(:uid)

    return if deleted_events.blank?

    upcoming_events.where(uid: deleted_events).destroy_all
  end

  def set_fb_page_token(user)
    graph = Koala::Facebook::API.new(user.access_token)
    self.page_access_token = graph.get_page_access_token(facebook_page_id)
  end

  def last_imported
    if last_import_at
      "Last imported #{time_ago_in_words(last_import_at)} ago"
    else
      'Never imported'
    end
  end

  # Get a count of all the events this week
  def events_this_week
    events.find_by_week(Time.now).count
  end

  # Who should be contacted about this calendar?
  def contact_information
    if public_contact_email
      [ public_contact_email, public_contact_name ]
    elsif partner&.public_email
      [ partner.public_email, partner.public_name ]
    elsif place&.public_email
      [ place.public_email, place.public_name ]
    else
      false
    end
  end

  private

  def source_supported
    CalendarParser.new(self).validate_feed
    self.is_working = true
    self.critical_error = nil
  rescue CalendarParser::InaccessibleFeed, CalendarParser::UnsupportedFeed => e
    critical_import_failure(e, false)
  end

  # Import events from given URL
  def events_from_source(from)
    CalendarParser.new(self, { from: from }).parse
  end

  def get_place_or_address(event_data)
    location = event_data.location

    return (strategy.event_override? ? { place_id: place_id } : {}) if location.blank?

    postcode   = event_data.postcode
    regexp     = postcode.present? ? Regexp.new("#{postcode.strip}|UK|United Kingdom") : Regexp.new('UK|United Kingdom')
    components = location.split(', ').map { |component| component.gsub(regexp, '').strip }.reject(&:blank?)

    if place = Partner.find_by('lower(name) IN (?)', components.map(&:downcase))
      return [ :place_id, place.id ]
    else
      return Address.search(location, components, postcode)
    end
  end

end
