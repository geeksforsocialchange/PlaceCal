# frozen_string_literal: true

# == Schema Information
#
# Table name: calendars
#
#  id                   :bigint           not null, primary key
#  api_token            :string
#  calendar_state       :string           default("idle")
#  checksum_updated_at  :datetime
#  critical_error       :text
#  feed_empty_since     :datetime
#  import_started_at    :datetime
#  importer_mode        :string           default("auto")
#  importer_used        :string
#  is_working           :boolean          default(TRUE), not null
#  last_checksum        :string
#  last_import_at       :datetime
#  name                 :string           not null
#  notice_count         :integer
#  notices              :jsonb
#  public_contact_email :string
#  public_contact_name  :string
#  public_contact_phone :string
#  source               :string           not null
#  strategy             :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  import_job_id        :bigint
#  organiser_id         :bigint           not null
#  place_id             :bigint
#
# Indexes
#
#  index_calendars_on_calendar_state  (calendar_state)
#  index_calendars_on_organiser_id    (organiser_id)
#  index_calendars_on_place_id        (place_id)
#  index_calendars_source             (source) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organiser_id => partners.id)
#  fk_rails_...  (place_id => partners.id)
#
class Calendar < ApplicationRecord
  # ==== Includes / Extends ====
  include ActionView::Helpers::DateHelper
  include Validation
  include Calendar::ImportState
  extend Enumerize

  # ==== Constants ====

  self.inheritance_column = nil

  ALLOWED_STATES = %i[idle in_queue in_worker error bad_source].freeze

  # Busy time after which a calendar with no recorded job (legacy rows, CLI imports) counts as stuck.
  STUCK_IMPORT_THRESHOLD = 2.hours

  # Skips just-queued attempts so a concurrent re-enqueue can't be reset by a stale snapshot.
  STUCK_IMPORT_GRACE = 5.minutes

  # Attributes that change what an import fetches
  FEED_ATTRIBUTES = %w[source importer_mode api_token].freeze

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
  self.ignored_columns += %w[is_working]

  # Columns marked (nullable) have no NOT NULL constraint in the DB.
  attribute :api_token,            :string                       # nullable
  attribute :checksum_updated_at,  :datetime                     # nullable
  attribute :critical_error,       :text                         # nullable
  attribute :import_job_id,        :integer, limit: 8            # nullable, Solid Queue job driving the current attempt
  attribute :import_started_at,    :datetime                     # nullable — when the current import attempt was queued/started
  attribute :importer_mode,        :string, default: 'auto'      # nullable
  attribute :importer_used,        :string                       # nullable
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
  # Normalised on assignment, so the form's blank field doesn't count as a feed change
  normalizes :api_token, with: ->(token) { token.strip.presence }

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

  # ==== Scopes ====
  scope :busy, -> { where(calendar_state: %w[in_queue in_worker]) }

  # Busy, and either their job is no longer running or, with no job recorded, they've been busy longer than the threshold
  scope :stuck_imports, lambda { |threshold = STUCK_IMPORT_THRESHOLD|
    running_jobs = SolidQueue::Job.where(finished_at: nil).where.not(id: SolidQueue::FailedExecution.select(:job_id))
    started = arel_table[:import_started_at]

    job_gone = busy.where(import_started_at: ...STUCK_IMPORT_GRACE.ago).where.not(import_job_id: nil)
                   .where.not(import_job_id: running_jobs.select(:id))
    untracked = busy.where(import_job_id: nil).where(started.eq(nil).or(started.lt(threshold.ago)))
    job_gone.or(untracked)
  }
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
  before_save :clear_status_on_feed_change
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

  # Reset busy calendars whose import job is gone, so the next scan can requeue them.
  # @param threshold [ActiveSupport::Duration] busy time before a calendar with no recorded job is reset
  # @return [Array<Integer>] ids of the calendars that were reset
  def self.reset_stuck_imports!(threshold: STUCK_IMPORT_THRESHOLD)
    ids = transaction do
      # SKIP LOCKED passes over a calendar that queue_for_import! is re-queueing right now
      stuck_imports(threshold).lock('FOR UPDATE SKIP LOCKED').pluck(:id).tap do |found|
        where(id: found).update_all(calendar_state: 'idle', import_job_id: nil) # rubocop:disable Rails/SkipsModelValidations
      end
    end
    Rails.logger.warn("[Calendar] Reset #{ids.size} stuck calendar(s) to idle: #{ids.join(', ')}") if ids.any?
    ids
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

    versions.order(created_at: :desc).group_by { |version| version.created_at.to_date }
  end

  # @return [Integer] number of events starting this week
  def events_this_week
    events.find_by_week(Time.zone.today).count
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
    queue_for_import! false, Time.current
  end

  # @return [Boolean] whether the stored source, type or API key differ from this copy's
  def feed_edited_since_loaded?
    self.class.where(id:).pick(*FEED_ATTRIBUTES) != FEED_ATTRIBUTES.map { |a| self[a] }
  end

  # @return [Boolean] whether unsaved changes alter what an import fetches
  def feed_changed?
    FEED_ATTRIBUTES.any? do |attr|
      attribute_changed?(attr) && attribute_was(attr).to_s.strip.presence != self[attr].to_s.strip.presence
    end
  end

  # is calendar being worked on by our backend?
  def busy?
    calendar_state.in_queue? || calendar_state.in_worker?
  end

  # is a user allowed to requeue a calendar for import?
  def can_be_requeued?
    calendar_state.idle? || calendar_state.bad_source?
  end

  private

  # ==== Private methods ====

  # called for validation
  def check_source_reachable
    return unless source_changed?
    return if errors[:source].any?

    CalendarImporter::CalendarImporter.new(self).check_source!
  rescue CalendarImporter::Exceptions::InaccessibleFeed => e
    errors.add :source, "The source URL returned an invalid code (#{e})"
  rescue CalendarImporter::Exceptions::UnsupportedFeed
    errors.add :source, 'Unable to autodetect calendar format, please pick an option from the list below'
  end

  def clear_status_on_feed_change
    return unless persisted? && feed_changed?

    self.critical_error = nil
    self.notices = nil
    self.last_import_at = nil
    self.last_checksum = nil
    self.feed_empty_since = nil
  end
end
