# frozen_string_literal: true

# == Schema Information
#
# Table name: events
#
#  id                       :bigint           not null, primary key
#  description              :text
#  description_html         :string
#  dtend                    :datetime
#  dtstart                  :datetime         not null
#  footer                   :text
#  image                    :string
#  image_source_url         :string
#  is_active                :boolean          default(TRUE), not null
#  price_currency           :string
#  price_from               :decimal(10, 2)
#  publisher_url            :string
#  raw_location_from_source :text
#  rrule                    :jsonb
#  sold_out                 :boolean
#  source_categories        :jsonb
#  source_organiser         :string
#  status                   :string           default("scheduled"), not null
#  summary                  :text             not null
#  summary_html             :string
#  ticket_url               :string
#  uid                      :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  address_id               :bigint
#  calendar_id              :bigint
#  online_address_id        :bigint
#  organiser_id             :bigint           not null
#  place_id                 :bigint
#
# Indexes
#
#  index_events_address_id                   (address_id)
#  index_events_calendar_id_dtstart          (calendar_id,dtstart)
#  index_events_dtstart                      (dtstart)
#  index_events_on_online_address_id         (online_address_id)
#  index_events_on_organiser_id_and_dtstart  (organiser_id,dtstart)
#  index_events_on_place_id                  (place_id)
#  index_events_uid                          (uid)
#  index_events_unique_per_calendar          (calendar_id,uid,dtstart,dtend) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (calendar_id => calendars.id)
#  fk_rails_...  (online_address_id => online_addresses.id)
#  fk_rails_...  (organiser_id => partners.id)
#  fk_rails_...  (place_id => partners.id)
#
class Event < ApplicationRecord
  # ==== Includes / Extends ====
  has_paper_trail ignore: %i[rrule]

  include HtmlRenderCache
  include EventDateScopes
  include EventDisplay
  include EventImage
  include EventJsonLd
  include Permalinkable

  # ==== Constants ====
  VERSION_RETENTION = 1.year
  VERSION_PRUNE_BATCH_SIZE = 5_000
  # Calendars with these strategies can import events that have no place, address or online link
  LOCATION_OPTIONAL_STRATEGIES = %w[event no_location online_only].freeze
  # Cancelled and postponed events stay listed, marked as such, so people who planned to go find out
  STATUSES = %w[scheduled cancelled postponed].freeze
  # Exhibitions and festivals: listed while they are on rather than only on their first day
  LONG_RUNNING_AFTER = 3.days
  LONG_RUNNING_SQL = "events.dtend > events.dtstart + interval '3 days'"
  NOT_LONG_RUNNING_SQL = "(events.dtend IS NULL OR NOT (#{LONG_RUNNING_SQL}))".freeze
  # Long-running wins over repeating, so every event is exactly one type
  TYPE_SQL = {
    'one_off' => "#{NOT_LONG_RUNNING_SQL} AND (events.rrule IS NULL OR events.rrule = 'false'::jsonb)",
    'repeating' => "#{NOT_LONG_RUNNING_SQL} AND events.rrule <> 'false'::jsonb",
    'long_running' => LONG_RUNNING_SQL
  }.freeze
  # A public event URL on any host, with or without a scheme or format, or a bare path
  EVENT_URL = %r{\A(?:[a-z][a-z\d+.-]*://)?[^/?#\s]*/events/(\d+)(?:\.[a-z]+)?/?(?:[?#]\S*)?\z}i

  # ==== Attributes ====
  # Columns marked (nullable) have no NOT NULL constraint in the DB.
  attribute :description,              :text                        # nullable
  attribute :description_html,         :string                      # nullable, populated by HtmlRenderCache
  attribute :dtend,                    :datetime                    # nullable
  attribute :dtstart,                  :datetime                    # NOT NULL
  attribute :footer,                   :text                        # nullable
  attribute :image_source_url,         :string                      # nullable, the source's URL for the stored image
  attribute :is_active,                :boolean, default: true      # NOT NULL
  attribute :price_currency,           :string                      # nullable, ISO 4217 code for price_from
  attribute :price_from,               :decimal                     # nullable, lowest ticket price in pounds (not pence); 0 is free
  attribute :publisher_url,            :string                      # nullable
  attribute :raw_location_from_source, :text                        # nullable
  attribute :rrule,                    :json                        # nullable — Array<Hash{table: {frequency: String}}>, or false
  attribute :sold_out,                 :boolean                     # nullable, nil when the source doesn't say
  attribute :source_categories,        :json                        # nullable, Array<String> as the source gave them
  attribute :source_organiser,         :string                      # nullable, the organiser name the source gave
  attribute :status,                   :string, default: 'scheduled' # NOT NULL, one of STATUSES
  attribute :summary,                  :text                        # NOT NULL
  attribute :summary_html,             :string                      # nullable, populated by HtmlRenderCache
  attribute :ticket_url,               :string                      # nullable, where tickets are bought, if not the webpage
  attribute :uid,                      :string                      # nullable

  html_render_cache :description
  html_render_cache :summary
  permalink_resource 'events'

  # ==== Associations ====
  belongs_to :organiser, class_name: 'Partner', optional: true
  belongs_to :place, class_name: 'Partner', optional: true
  belongs_to :address, optional: true
  belongs_to :online_address, optional: true
  belongs_to :calendar, optional: true

  # ==== Validations ====
  validates :summary, :dtstart, :organiser, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :price_from, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price_currency, format: { with: /\A[A-Z]{3}\z/ }, allow_nil: true
  validate :require_location
  validate :unique_event, on: :create

  # ==== Scopes ====
  # Events whose organiser is based in, or serves, any of the neighbourhoods
  scope :for_neighbourhoods, lambda { |neighbourhoods|
    based_there = Partner.joins(:address).where(addresses: { neighbourhood_id: neighbourhoods }).select(:id)
    serving_there = ServiceArea.where(neighbourhood_id: neighbourhoods).select(:partner_id)
    where(organiser_id: based_there).or(where(organiser_id: serving_there))
  }

  scope :with_tags, ->(tags) { joins(organiser: :partner_tags).where(partner_tags: { tag_id: tags }) }

  scope :in_place, ->(place) { where(place:) }
  scope :by_organiser, ->(organiser) { where(organiser:) }
  scope :by_organiser_or_place, ->(organiser) { in_place(organiser).or(by_organiser(organiser)) }

  # Hiding a partner is a moderation action, so its events leave every public listing
  scope :with_visible_organiser, lambda {
    where('NOT EXISTS (SELECT 1 FROM partners hidden_organisers ' \
          'WHERE hidden_organisers.id = events.organiser_id AND hidden_organisers.hidden)')
  }

  scope :sort_by_summary, -> { order(summary: :asc).order(:dtstart) }
  scope :sort_by_time, -> { order(dtstart: :asc).order(summary: :asc) }

  scope :without_matching_times, lambda { |time_pairs|
    return none if time_pairs.empty?

    matching = time_pairs.map { |start_time, end_time| arel_table[:dtstart].eq(start_time).and(arel_table[:dtend].eq(end_time)) }
    where.not(matching.reduce(:or))
  }

  scope :long_running, -> { where(LONG_RUNNING_SQL) }

  # @param types [Array<String>] keys of TYPE_SQL
  scope :of_types, ->(types) { types.empty? ? none : where(types.map { "(#{TYPE_SQL.fetch(it)})" }.join(' OR ')) }

  # Started before the day and not ended by its start
  scope :running_on, lambda { |day|
    midnight = day.to_date.in_time_zone
    long_running.where(dtstart: ...midnight).where('events.dtend > ?', midnight)
  }

  # What a partner's listing holds. One where, not .or, so it chains onto relations with joins
  scope :upcoming_or_running, lambda { |day = Time.zone.today|
    where("events.dtstart >= :midnight OR (#{LONG_RUNNING_SQL} AND events.dtend > :midnight)", midnight: day.to_date.in_time_zone)
  }

  # ==== Callbacks ====
  before_save :sanitize_rrule

  # ==== Class methods ====
  # Deletes PaperTrail versions older than VERSION_RETENTION.
  # @return [Integer] number of deleted versions
  def self.prune_old_versions!
    count = PaperTrail::Version.where(item_type: name, created_at: ...VERSION_RETENTION.ago)
                               .in_batches(of: VERSION_PRUNE_BATCH_SIZE)
                               .delete_all
    Rails.logger.info("[Event] Pruned #{count} version(s) older than #{VERSION_RETENTION.inspect}")
    count
  end

  # Takes the times rather than an event so components can ask it of test doubles
  # @return [Boolean]
  def self.long_running?(dtstart, dtend)
    dtend.present? && dtend - dtstart > LONG_RUNNING_AFTER.to_i
  end

  # Feeds end all-day events at the next midnight, which is not a day the event is on
  # @return [Date]
  def self.last_day(dtend)
    dtend == dtend.beginning_of_day ? dtend.to_date.prev_day : dtend.to_date
  end

  # @param text [String] a public event URL or a bare event ID
  # @return [Event, nil]
  def self.lookup(text)
    text = text.to_s.strip
    id = text[/\A\d+\z/] || text[EVENT_URL, 1]
    find_by(id:) if id
  end

  # ==== Instance methods ====
  def long_running? = self.class.long_running?(dtstart, dtend)

  # Other events from the same calendar with the same summary, such as a repeat's other dates
  # @return [ActiveRecord::Relation<Event>]
  def siblings
    return Event.none if calendar_id.nil?

    Event.where(calendar_id:, summary:).where.not(id:)
  end

  def cancelled? = status == 'cancelled'
  def postponed? = status == 'postponed'

  # Cancelled or postponed: not happening on the date listed
  def called_off? = cancelled? || postponed?

  # @return [Neighbourhood, nil]
  def neighbourhood
    address&.neighbourhood
  end

  # @return [Address, nil] the best available address for this event
  def resolved_address
    # A place without an address mustn't borrow the organiser's, which would be shown as the place's
    address || (partner_at_location || organiser)&.address
  end

  # @return [String] human-readable address string, or empty string
  def location
    resolved_address.to_s
  end

  # @return [Partner, nil] the visible place partner, or a visible venue matching the address
  def partner_at_location
    return @partner_at_location if defined?(@partner_at_location)

    @partner_at_location = (place unless place&.hidden) || Partner.matching_venue_for(address)
  end

  # By its end, so a multi-day event still running isn't over
  # @return [Boolean]
  def past?
    (dtend || dtstart) < DateTime.current.beginning_of_day
  end

  private

  def sanitize_rrule
    self.rrule = false if rrule.nil? || rrule == []
  end

  def require_location
    return if LOCATION_OPTIONAL_STRATEGIES.include?(calendar&.strategy)
    return if online_address_id || place_id || address_id

    errors.add(:base, :no_location, location: raw_location_from_source)
  end

  def unique_event
    return unless Event.exists?(uid:, dtstart:, summary:, calendar_id:)

    errors.add(:base, :duplicate, calendar_id:, calendar: calendar&.name)
  end
end
