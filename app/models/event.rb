# frozen_string_literal: true

# == Schema Information
#
# Table name: events
#
#  id                       :bigint           not null, primary key
#  are_spaces_available     :string
#  description              :text
#  description_html         :string
#  dtend                    :datetime
#  dtstart                  :datetime         not null
#  footer                   :text
#  is_active                :boolean          default(TRUE), not null
#  notices                  :jsonb
#  publisher_url            :string
#  raw_location_from_source :text
#  rrule                    :jsonb
#  source_categories        :jsonb
#  source_organiser         :string
#  summary                  :text             not null
#  summary_html             :string
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
  include EventJsonLd
  include Permalinkable

  # ==== Constants ====
  VERSION_RETENTION = 1.year
  VERSION_PRUNE_BATCH_SIZE = 5_000

  # ==== Attributes ====
  self.ignored_columns += %w[notices]

  # Columns marked (nullable) have no NOT NULL constraint in the DB.
  attribute :are_spaces_available,     :string                      # nullable
  attribute :description,              :text                        # nullable
  attribute :description_html,         :string                      # nullable, populated by HtmlRenderCache
  attribute :dtend,                    :datetime                    # nullable
  attribute :dtstart,                  :datetime                    # NOT NULL
  attribute :footer,                   :text                        # nullable
  attribute :is_active,                :boolean, default: true      # NOT NULL
  attribute :publisher_url,            :string                      # nullable
  attribute :raw_location_from_source, :text                        # nullable
  attribute :rrule,                    :json                        # nullable — Array<Hash{table: {frequency: String}}>, or false
  attribute :source_categories,        :json                        # nullable, Array<String> as the source gave them
  attribute :source_organiser,         :string                      # nullable, the organiser name the source gave
  attribute :summary,                  :text                        # NOT NULL
  attribute :summary_html,             :string                      # nullable, populated by HtmlRenderCache
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
  validate :require_location
  validate :unique_event, on: :create # If we are updating the event we don't want it to trigger!

  # ==== Scopes ====
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
      .where(partner_tags: { tag_id: tags.map(&:id) })
  }

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

    conditions = time_pairs.map { |s, e| arel_table[:dtstart].eq(s).and(arel_table[:dtend].eq(e)) }
    matching = conditions.reduce(:or)
    where.not(matching)
  }

  scope :one_off_events_only, -> { where(rrule: false) }
  scope :repeating_events_only, -> { where.not(rrule: false) }

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

  # ==== Instance methods ====

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

  # Whether the event is over (dtend-aware, so a multi-day event still
  # running doesn't count). Used to noindex stale event pages.
  # @return [Boolean]
  def past?
    (dtend || dtstart) < DateTime.current.beginning_of_day
  end

  private

  # ==== Private methods ====

  def sanitize_rrule
    self.rrule = false if rrule.nil? || rrule == []
  end

  def require_location
    # 'event', 'no_location', and 'online_only' do not require a Location
    return if %w[event no_location online_only].include?(calendar&.strategy)

    return if online_address_id || place_id || address_id

    errors.add(:base, 'No place or address could be created or found for ' \
                      "the event location: #{raw_location_from_source}")
  end

  # Ensures that the event added is unique
  # Checks for a duplicate event with the properties dtstart, summary, and calendar_id
  def unique_event
    return unless Event.where(uid:,
                              dtstart:,
                              summary:,
                              calendar_id:)
                       .any?

    errors.add(:base, 'Unfortunately this event is a duplicate of an ' \
                      "existing event for calendar: #{calendar_id} " \
                      "('#{calendar.name}')")
  end
end
