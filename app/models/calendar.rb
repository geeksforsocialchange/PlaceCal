# frozen_string_literal: true

class Calendar < ApplicationRecord
  # ==== Includes / Extends ====
  include ActionView::Helpers::DateHelper
  include Validation
  extend Enumerize

  # ==== Constants ====

  self.inheritance_column = nil

  ALLOWED_STATES = %i[idle in_queue in_worker error bad_source].freeze

  # ==== Enums / Enumerize ====
  # Defines the strategy this Calendar uses to assign events to locations.
  # @attr [Enumerable<Symbol>] :strategy
  enumerize(
    :strategy,
    in: %i[place event_override event room_number no_location online_only],
    default: :place,
    scope: true
  )
  # strategy -- managed by enumerize, attribute declaration skipped

  # State machine values
  enumerize(
    :calendar_state,
    in: ALLOWED_STATES,
    default: :idle
  )
  # calendar_state -- managed by enumerize, attribute declaration skipped

  # ==== Attributes ====
  # Columns marked (nullable) have no NOT NULL constraint in the DB.
  attribute :api_token,            :string                       # nullable
  attribute :checksum_updated_at,  :datetime                     # nullable
  attribute :critical_error,       :text                         # nullable
  attribute :importer_mode,        :string, default: 'auto'      # nullable
  attribute :importer_used,        :string                       # nullable
  attribute :is_working,           :boolean, default: true       # NOT NULL
  attribute :last_checksum,        :string                       # nullable
  attribute :last_import_at,       :datetime                     # nullable
  attribute :name,                 :string                       # NOT NULL
  attribute :notice_count,         :integer                      # nullable
  attribute :notices,              :json                         # nullable — Array<String>, importer messages
  attribute :public_contact_email, :string                       # nullable
  attribute :public_contact_name,  :string                       # nullable
  attribute :public_contact_phone, :string                       # nullable
  attribute :source,               :string                       # NOT NULL

  alias_attribute :to_s, :name

  auto_strip_attributes :name, :source, :public_contact_name, :public_contact_email, :public_contact_phone

  # ==== Associations ====
  belongs_to :organiser, class_name: 'Partner', optional: true
  belongs_to :place, class_name: 'Partner', optional: true
  has_many :events, dependent: :destroy

  # ==== Validations ====
  validates :name, :organiser, :source, presence: true
  validates :place, presence: { if: :requires_default_location?,
                                message: "can't be blank with this strategy" }
  validates :source, uniqueness: { message: 'calendar source already in use' },
                     format: { with: CALENDAR_URL_REGEX, message: 'not a valid URL' }

  validate :check_source_reachable
  validate :source_not_private_ip

  # ==== Scopes ====
  scope :that_appear_on_site, lambda { |site|
    site_partnership_tag_ids = site.tags.map(&:id)

    if site_partnership_tag_ids.length.positive?
      return Calendar.left_joins(organiser: %i[address service_areas partnerships])
                     .where(
                       '(partner_tags.tag_id IN (:tags) AND '\
                       '(addresses.neighbourhood_id in (:neighbourhood_ids) OR '\
                       'service_areas.neighbourhood_id in (:neighbourhood_ids)))',
                       neighbourhood_ids: site.owned_neighbourhood_ids,
                       tags: site_partnership_tag_ids
                     )
                     .distinct
    else
      return Calendar.left_joins(organiser: %i[address service_areas])
                     .left_joins(events: %i[address])
                     .where(
                       '(addresses.neighbourhood_id in (:neighbourhood_ids) OR '\
                       'service_areas.neighbourhood_id in (:neighbourhood_ids))',
                       neighbourhood_ids: site.owned_neighbourhood_ids
                     )
                     .distinct
    end
  }

  # ==== Callbacks ====
  before_save :clear_status_on_source_change
  before_save :update_notice_count

  after_create :automatically_queue_calendar

  # ==== Class methods ====

  # @return [Time] the furthest future date to import events up to
  def self.import_up_to
    1.year.from_now
  end

  # Queue every calendar for import.
  # @param force [Boolean] bypass redundant-import checks
  # @param from [Date] start date for the import window
  # @return [void]
  def self.queue_all_for_import!(force: false, from: Date.current.beginning_of_day)
    find_each do |calendar|
      calendar.queue_for_import! force, from
    end
  end

  # ==== Instance methods ====

  # @return [Boolean] whether this strategy requires a default place
  def requires_default_location?
    %i[place room_number event_override].include? strategy.to_sym
  end

  # PaperTrail-based activity log for the last 2 weeks, including deletions.
  # @return [Hash{Date => Array<PaperTrail::Version>}] versions grouped by date
  def recent_activity
    versions = PaperTrail::Version.with_item_keys('Event', event_ids).where(created_at: 2.weeks.ago..)
    versions = versions.or(PaperTrail::Version.destroys
                                              .where("item_type = 'Event' AND object @> ? AND created_at >= ?",
                                                     { calendar_id: id }.to_json, 2.weeks.ago))

    versions = versions.order(created_at: :desc).group_by { |version| version.created_at.to_date }
  end

  # @return [Integer] number of events starting this week
  def events_this_week
    events.find_by_week(Time.now).count
  end

  # @return [Array(String, String), false] [email, name] pair, or false if none available
  def contact_information
    if public_contact_email
      [public_contact_email, public_contact_name]
    elsif organiser&.public_email
      [organiser.public_email, organiser.public_name]
    elsif place&.public_email
      [place.public_email, place.public_name]
    else
      false
    end
  end

  # Syncs notice_count with the notices array. Called before save.
  # @return [void]
  def update_notice_count
    self.notice_count = (notices || []).count if notices_changed?
  end

  # @return [void]
  def automatically_queue_calendar
    queue_for_import! false, DateTime.now
  end

  #
  # calendar state mutators
  #

  # Push calendar into the import queue.
  # @param force_import [Boolean] bypass redundant-import checks
  # @param from_date [Time] start point for the import window
  # @return [void]
  def queue_for_import!(force_import, from_date = Time.now)
    without_timestamps do
      return if is_busy?

      update! calendar_state: :in_queue, notices: nil
      CalendarImporterJob.perform_later id, from_date, force_import
    end
  end

  # Flag that importing has started.
  # @return [void]
  def flag_start_import_job!
    without_timestamps do
      return unless calendar_state.in_queue?

      update! calendar_state: :in_worker, notices: nil
    end
  end

  # Flag that importing completed successfully; stores notices and timestamp.
  # @param notices [Array<String>] messages generated during import
  # @param importer_used [String] name of the importer that ran
  # @return [void]
  def flag_complete_import_job!(notices, importer_used)
    without_timestamps do
      return unless calendar_state.in_worker?

      update!(
        calendar_state: :idle,
        notices: notices,
        last_import_at: DateTime.current,
        critical_error: nil,
        importer_used: importer_used
      )
    end
  end

  # Record that the source payload checksum has changed.
  # @param checksum [Integer] checksum of the retrieved source payload
  # @return [void]
  def flag_checksum_change!(checksum)
    without_timestamps do
      update!(
        last_checksum: checksum,
        checksum_updated_at: DateTime.current
      )
    end
  end

  # Mark calendar as having an unreachable/invalid source.
  # @param problem [String] description of the source issue
  # @return [void]
  def flag_bad_source!(problem)
    without_timestamps do
      return unless calendar_state.in_worker?

      # we need the state to be valid so we discard everything
      # before saving error
      reload

      self.calendar_state = :bad_source
      self.critical_error = problem
      save!
    end
  end

  # Flag that an import error occurred; all future processing ceases
  # until the user resets this calendar.
  # NOTE: reloads the model, clobbering any in-memory state.
  # @param problem [String] description of the import failure
  # @return [void]
  def flag_error_import_job!(problem)
    without_timestamps do
      return unless calendar_state.in_worker?

      # we need the state to be valid so we discard everything
      # before saving error
      reload

      self.calendar_state = :error
      self.critical_error = problem
      save validate: false
    end
  end

  # @return [String] Bootstrap colour name for the current state badge
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

  # ==== Private methods ====

  # Wraps a block in a transaction with timestamps disabled, so that
  # state-machine transitions don't clobber updated_at.
  def without_timestamps
    transaction do
      Calendar.record_timestamps = false
      yield
    ensure
      Calendar.record_timestamps = true
    end
  end

  def source_not_private_ip
    return unless source.present? && source_changed?
    return if errors[:source].any?

    errors.add :source, 'must not point to a private network address' if Validation.private_ip?(source)
  end

  # called for validation
  def check_source_reachable
    return unless source_changed?
    return if errors[:source].any?

    # The calendar importer will raise an exception if the source
    #   URL has a problem
    CalendarImporter::CalendarImporter.new(self)
  rescue CalendarImporter::Exceptions::InaccessibleFeed => e
    errors.add :source, "The source URL returned an invalid code (#{e})"
  rescue CalendarImporter::Exceptions::UnsupportedFeed => e
    errors.add :source, 'Unable to autodetect calendar format, please pick an option from the list below'
  end

  def clear_status_on_source_change
    return unless source_changed?

    self.critical_error = nil
    self.notices = nil
    self.last_import_at = nil
  end
end
