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
  before_save :update_notice_count

  attribute :is_facebook_page, :boolean, default: false
  attribute :facebook_page_id, :string

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

  # State machine values
  enumerize(
    :calendar_state,
    in: %i[idle in_queue in_worker error],
    default: :idle
  )

  scope :where_busy, -> { where(calendar_state: %i[in_queue in_worker]) }
  scope :where_idle, -> { where(calendar_state: :idle) }
  scope :where_errored, -> { where(calendar_state: :error) }


  # We need a default location for some strategies
  def requires_default_location?
    %i[place room_number event_override].include? strategy.to_sym
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

  def set_fb_page_token(user)
    graph = Koala::Facebook::API.new(user.access_token)
    self.page_access_token = graph.get_page_access_token(facebook_page_id)
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

  # called before save
  def source_supported
    # The calendar importer will raise an exception if the source
    #   URL has a problem
    CalendarImporter::CalendarImporter.new(self)

  rescue CalendarImporter::CalendarImporter::InaccessibleFeed, CalendarImporter::CalendarImporter::UnsupportedFeed => e
    flag_error_import_job! e.to_s
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
      return unless calendar_state.idle? || calendar_state.error?

      update! calendar_state: :in_queue

      CalendarImporterJob.perform_later self.id, from_date, force_import
    end
  end

  # flag calendar record that importing has started
  #
  # @return nothing
  def flag_start_import_job!
    transaction do
      return unless calendar_state.in_queue?
      update! calendar_state: :in_worker
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

  # Flag calendar record a problem has occurred and that all
  # future processing will cease until the user resets this calendar
  # elsewhere
  #
  # @param problem [String]
  #   string describing the basic problem the importer failed on
  #
  # @eturn
  #   nothing
  def flag_error_import_job!(problem)
    transaction do
      return unless calendar_state.in_worker?

      update!(
        calendar_state: :error,
        critical_error: problem
      )
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
end
