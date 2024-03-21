# frozen_string_literal: true

# app/models/calendar.rb
class Calendar < ApplicationRecord
  include ActionView::Helpers::DateHelper
  include Validation
  extend Enumerize

  CALENDAR_REGEX = %r{\A(?:(?:(https?|webcal))://)(?:\S+(?::\S*)?@)?(?:(?!10(?:\.\d{1,3}){3})(?!127(?:\.\d{1,3}){3})(?!169\.254(?:\.\d{1,3}){2})(?!192\.168(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,})))(?::\d{2,5})?(?:/[^\s]*)?\z}i.freeze

  self.inheritance_column = nil

  belongs_to :partner, optional: true
  belongs_to :place, class_name: 'Partner', optional: true
  has_many :events, dependent: :destroy

  validates :name, :partner, :source, presence: true
  validates :place, presence: { if: :requires_default_location?,
                                message: "can't be blank with this strategy" }
  validates :source, uniqueness: { message: 'calendar source already in use' },
                     format: { with: CALENDAR_REGEX, message: 'not a valid URL' }

  validate :check_source_reachable

  before_save :update_notice_count

  # Output the calendar's name when it's requested as a string
  alias_attribute :to_s, :name

  # Defines the strategy this Calendar uses to assign events to locations.
  # @attr [Enumerable<Symbol>] :strategy
  enumerize(
    :strategy,
    in: %i[event place room_number event_override no_location online_only],
    default: :place,
    scope: true
  )

  ALLOWED_STATES = %i[idle in_queue in_worker error bad_source].freeze
  # State machine values
  enumerize(
    :calendar_state,
    in: ALLOWED_STATES,
    default: :idle
  )

  scope :that_appear_on_site, lambda { |site|
    site_neighbourhood_ids = site.owned_neighbourhoods.map(&:id)
    site_partnership_tag_ids = site.tags.map(&:id)

    if site_partnership_tag_ids.length.positive?
      return Calendar.left_joins(partner: %i[address service_areas partnerships])
                     .where(
                       '(partner_tags.tag_id IN (:tags) AND '\
                       '(addresses.neighbourhood_id in (:neighbourhood_ids) OR '\
                       'service_areas.neighbourhood_id in (:neighbourhood_ids)))',
                       neighbourhood_ids: site_neighbourhood_ids,
                       tags: site_partnership_tag_ids
                     )
                     .distinct
    else
      return Calendar.left_joins(partner: %i[address service_areas])
                     .where(
                       '(addresses.neighbourhood_id in (:neighbourhood_ids) OR '\
                       'service_areas.neighbourhood_id in (:neighbourhood_ids))',
                       neighbourhood_ids: site_neighbourhood_ids
                     )
                     .distinct
    end
  }

  # We need a default location for some strategies
  def requires_default_location?
    %i[place room_number event_override].include? strategy.to_sym
  end

  # Output recent calendar import activity
  # This uses PaperTrail to get historical records of the Event models, including deletes
  # It does this to show a "event added" / "event removed" thing
  def recent_activity
    versions = PaperTrail::Version.with_item_keys('Event', event_ids).where('created_at >= ?', 2.weeks.ago)
    versions = versions.or(PaperTrail::Version.destroys
                                              .where("item_type = 'Event' AND object @> ? AND created_at >= ?",
                                                     { calendar_id: id }.to_json, 2.weeks.ago))

    versions = versions.order(created_at: :desc).group_by { |version| version.created_at.to_date }
  end

  # Get a count of all the events this week
  def events_this_week
    events.find_by_week(Time.now).count
  end

  # Who should be contacted about this calendar?
  def contact_information
    if public_contact_email
      [public_contact_email, public_contact_name]
    elsif partner&.public_email
      [partner.public_email, partner.public_name]
    elsif place&.public_email
      [place.public_email, place.public_name]
    else
      false
    end
  end

  #
  # calendar importer support methods
  #

  def self.import_up_to
    1.year.from_now
  end

  # internal model function
  def update_notice_count
    self.notice_count = (notices || []).count if notices_changed?
  end

  #
  # calendar state mutators
  #

  # push calendar into queue
  #
  # @param force_import [Boolean]
  #   boolean to bypass checks on redundant imports
  # @param from_date [String]
  #   date to use as the start point
  #
  # @return nothing
  def queue_for_import!(force_import, from_date)
    transaction do
      return if is_busy?

      Calendar.record_timestamps = false
      update! calendar_state: :in_queue

      CalendarImporterJob.perform_later id, from_date, force_import

    ensure
      Calendar.record_timestamps = true
    end
  end

  # flag calendar record that importing has started
  #
  # @return nothing
  def flag_start_import_job!
    transaction do
      return unless calendar_state.in_queue?

      Calendar.record_timestamps = false
      update! calendar_state: :in_worker

    ensure
      Calendar.record_timestamps = true
    end
  end

  # Flag calendar record that importing has completed successfully
  # and store a timestamp, checksum and notices
  #
  # @param notices [Array]
  #   array of strings of messages generated by the importer
  #   during its normal operation
  # @param checksum [integer]
  #   integer checksum of retrieved source payload
  # @return nothing
  def flag_complete_import_job!(notices, checksum, importer_used)
    transaction do
      return unless calendar_state.in_worker?

      Calendar.record_timestamps = false

      update!(
        calendar_state: :idle,
        notices: notices,
        last_checksum: checksum,
        last_import_at: DateTime.current,
        critical_error: nil,
        importer_used: importer_used
      )

    ensure
      Calendar.record_timestamps = true
    end
  end

  def flag_bad_source!(problem)
    transaction do
      return unless calendar_state.in_worker?

      # we need the state to be valid so we discard everything
      # before saving error
      reload

      Calendar.record_timestamps = false
      self.calendar_state = :bad_source
      self.critical_error = problem
      save!

    ensure
      Calendar.record_timestamps = true
    end
  end

  # Flag calendar record a problem has occurred and that all
  # future processing will cease until the user resets this calendar
  # elsewhere
  # NOTE: this reloads the model object so if you want to keep any
  # built up state then this WILL clobber that.
  #
  # @param problem [String]
  #   string describing the basic problem the importer failed on
  #
  # @eturn
  #   nothing
  def flag_error_import_job!(problem)
    transaction do
      return unless calendar_state.in_worker?

      # we need the state to be valid so we discard everything
      # before saving error
      reload

      Calendar.record_timestamps = false
      self.calendar_state = :error
      self.critical_error = problem
      save validate: false

    ensure
      Calendar.record_timestamps = true
    end
  end

  def state_colour
    case calendar_state
    when 'in_queue'
      'primary'
    when 'in_worker'
      'success'
    when 'error'
      'danger'
    else
      'info'
    end
  end

  # is calendar being worked on by our backend?
  def is_busy?
    calendar_state.in_queue? || calendar_state.in_worker?
  end

  # is a user allowed to requeue a calendar for import?
  def can_be_requeued?
    calendar_state.idle? || calendar_state.bad_source?
  end

  private

  # called for validation
  def check_source_reachable
    return unless source_changed?

    # The calendar importer will raise an exception if the source
    #   URL has a problem
    CalendarImporter::CalendarImporter.new(self)
  rescue CalendarImporter::Exceptions::InaccessibleFeed => e
    errors.add :source, "The source URL returned an invalid code (#{e})"
  rescue CalendarImporter::Exceptions::UnsupportedFeed => e
    errors.add :source, 'Unable to autodetect calendar format, please pick an option from the list below'
  end
end
