# frozen_string_literal: true

class Partner < ApplicationRecord
  # ==== Includes / Extends ====
  include Validation
  include PartnerJsonLd
  include Permalinkable
  extend FriendlyId
  include HtmlRenderCache

  # ==== Constants ====

  MAX_CATEGORIES = 3

  # ==== Attributes ====
  # Columns marked (nullable) have no NOT NULL constraint in the DB.
  attribute :accessibility_info,      :text                        # nullable
  attribute :accessibility_info_html, :string                      # nullable, populated by HtmlRenderCache
  attribute :admin_email,             :string                      # nullable
  attribute :admin_name,              :string                      # nullable
  attribute :booking_info,            :text                        # nullable
  attribute :calendar_email,          :string                      # nullable
  attribute :calendar_name,           :string                      # nullable
  attribute :calendar_phone,          :string                      # nullable
  attribute :can_be_assigned_events,  :boolean, default: false     # NOT NULL
  attribute :description,             :text                        # nullable
  attribute :description_html,        :string                      # nullable, populated by HtmlRenderCache
  attribute :facebook_link,           :string                      # nullable
  attribute :hidden,                  :boolean, default: false     # NOT NULL
  attribute :hidden_blame_id,         :integer                     # nullable
  attribute :hidden_reason,           :text                        # nullable
  attribute :hidden_reason_html,      :string                      # nullable, populated by HtmlRenderCache
  # image -- managed by CarrierWave, attribute declaration skipped
  attribute :instagram_handle,        :string                      # nullable
  attribute :is_a_place,              :boolean, default: false     # NOT NULL
  attribute :name,                    :string                      # NOT NULL
  attribute :opening_times,           :json                        # nullable — Array<Hash{dayOfWeek, opens, closes}>, schema.org OpeningHoursSpecification
  attribute :partner_email,           :string                      # nullable
  attribute :partner_name,            :string                      # nullable
  attribute :partner_phone,           :string                      # nullable
  attribute :public_email,            :string                      # nullable
  attribute :public_name,             :string                      # nullable
  attribute :public_phone,            :string                      # nullable
  attribute :slug,                    :string                      # nullable
  attribute :summary,                 :string                      # nullable
  attribute :summary_html,            :string                      # nullable, populated by HtmlRenderCache
  attribute :twitter_handle,          :string                      # nullable
  attribute :url,                     :string                      # nullable

  attr_accessor :accessed_by_user

  friendly_id :name, use: :slugged

  html_render_cache :description
  html_render_cache :summary
  html_render_cache :accessibility_info
  html_render_cache :hidden_reason

  auto_strip_attributes :name, :summary, :url, :twitter_handle, :instagram_handle, :facebook_link, :public_phone, :public_email
  permalink_resource 'partners'

  # ==== Associations ====
  has_and_belongs_to_many :users
  has_many :calendars, foreign_key: :organiser_id, dependent: :destroy, inverse_of: :organiser
  has_many :events, foreign_key: :organiser_id, dependent: :destroy, inverse_of: :organiser
  belongs_to :address, optional: true, dependent: :destroy

  has_many :partner_tags, dependent: :destroy
  has_many :tags, through: :partner_tags
  has_many :categories, through: :partner_tags, source: :tag, class_name: 'Category'
  has_many :facilities, through: :partner_tags, source: :tag, class_name: 'Facility'
  has_many :partnerships, through: :partner_tags, source: :tag, class_name: 'Partnership'

  has_many :service_areas, dependent: :destroy, before_remove: :check_remove_service_area
  has_many :service_area_neighbourhoods,
           through: :service_areas,
           source: :neighbourhood,
           class_name: 'Neighbourhood'

  has_many :article_partners, dependent: :destroy
  has_many :articles, through: :article_partners

  has_and_belongs_to_many :objects,
                          class_name: 'Partner',
                          join_table: :organisation_relationships,
                          foreign_key: 'partner_subject_id',
                          association_foreign_key: 'partner_object_id'

  has_and_belongs_to_many :subjects,
                          class_name: 'Partner',
                          join_table: :organisation_relationships,
                          foreign_key: 'partner_object_id',
                          association_foreign_key: 'partner_subject_id'

  accepts_nested_attributes_for :calendars, allow_destroy: true

  # If any of the address formfields are present we attempt to create an address
  # this will trigger the validation
  accepts_nested_attributes_for :address, reject_if: lambda { |c|
    [c[:city],
     c[:postcode],
     c[:street_address],
     c[:street_address2],
     c[:street_address3]].all?(&:blank?)
  }

  accepts_nested_attributes_for :service_areas, allow_destroy: true

  # ==== Uploaders ====
  mount_uploader :image, ImageUploader

  # ==== Validations ====
  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: {
              minimum: 5,
              too_short: 'must be at least 5 characters long'
            }
  validates :summary,
            length: {
              maximum: 200,
              too_long: 'maxmimum length is 200 characters'
            }
  validates :summary,
            presence: {
              if: ->(p) { p.description.present? },
              message: 'cannot have a description without a summary'
            }
  validates :url,
            format: { with: URL_REGEX, message: 'is invalid' },
            allow_blank: true
  validates :twitter_handle,
            format: { with: TWITTER_REGEX, message: 'invalid account name' },
            allow_blank: true
  validates :instagram_handle,
            format: { with: INSTAGRAM_REGEX, message: 'invalid account name' },
            allow_blank: true
  validates :facebook_link,
            format: { with: FACEBOOK_REGEX, message: 'invalid page name' },
            allow_blank: true
  validates :public_phone, :partner_phone,
            format: { with: UK_NUMBER_REGEX, message: 'invalid phone number' },
            allow_blank: true
  validates :public_email, :partner_email,
            format: { with: EMAIL_REGEX, message: 'invalid email address' },
            allow_blank: true
  validates :slug, uniqueness: true

  validates_associated :service_areas
  validates_associated :address

  validate :check_neighbourhood_access
  validate :neighbourhood_admin_address_access, on: %i[create update]
  validate :must_have_address_or_service_area
  validate :opening_times_is_json_or_nil
  validate :three_or_less_category_tags
  validate :partnership_admins_must_add_partnership, on: %i[create]
  validate :must_give_reason_to_hide
  validate :must_record_who_has_hidden

  # ==== Scopes ====
  scope :visible, -> { where(hidden: false) }
  scope :recently_updated, -> { order(updated_at: desc) }

  # only select partners that have addresses
  scope :with_address, lambda {
    where.not(address_id: nil)
  }

  # Get all Partners that manage at least one other Partner.
  scope :managers, lambda {
    joins('JOIN organisation_relationships o_r on o_r.partner_subject_id = partners.id')
      .where(o_r: { verb: :manages }).distinct
  }

  # ==== Delegates ====
  delegate :neighbourhood_id, to: :address, allow_nil: true

  # ==== Callbacks ====
  after_commit :refresh_neighbourhood_partners_count

  # ==== Class methods ====

  # Find a place-partner whose name matches one of the address street lines.
  # @param address [Address] the address to match against
  # @return [Partner, nil]
  def self.matching_venue_for(address)
    return unless address&.street_lines&.any? && address&.postcode

    Partner.left_joins(:address)
           .find_by(
             'can_be_assigned_events AND '\
             'lower(name) IN (:components) AND '\
             'lower(addresses.postcode) = (:postcode)',
             components: address.street_lines.map(&:downcase),
             postcode: address.postcode.downcase
           )
  end

  # ==== Instance methods ====

  # Strips leading @ from Twitter handles before saving.
  # @param handle [String, nil]
  # @return [String, nil]
  def twitter_handle=(handle)
    super(handle&.gsub('@', ''))
  end

  # @return [ActiveRecord::Relation<Partner>] partners that manage this one
  def managers
    subjects.where(organisation_relationships: { verb: :manages })
  end

  # @return [ActiveRecord::Relation<Partner>] partners this one manages
  def managees
    objects.where(organisation_relationships: { verb: :manages })
  end

  # @return [Array<Neighbourhood>] unique neighbourhoods from address + service areas
  def neighbourhoods
    arr = []
    arr << address.neighbourhood if address&.neighbourhood
    arr << service_areas&.map(&:neighbourhood) if service_areas
    arr.flatten.uniq
  end

  def to_s
    name
  end

  # @return [Boolean] whether FriendlyId should generate a new slug
  def should_generate_new_friendly_id?
    slug.blank?
  end

  # @return [Boolean]
  def has_service_areas?
    service_areas.any?
  end

  # Whether the current user is allowed to remove this partner's address.
  # @param user [User, nil]
  # @return [Boolean]
  def can_clear_address?(user = nil)
    return false if address.blank? || address.missing_values?
    return false if service_areas.empty?

    return false if user.blank?
    return true if user.root?
    return true if user.admin_for_partner?(id)

    # must admin for this address specifically
    user_hood_ids = user.owned_neighbourhood_ids
    user_hood_ids.include?(address.neighbourhood_id)
  end

  # Whether the user should see a warning before clearing the address
  # (i.e. their only link to this partner is through its address).
  # @param user [User]
  # @return [Boolean]
  def warn_user_clear_address?(user)
    return false if user.root?
    return false if user.admin_for_partner?(id)

    user_hood_ids = user.owned_neighbourhood_ids
    return true if user_hood_ids.empty?

    sa_hood_ids = service_areas.pluck(:neighbourhood_id)

    any_service_areas = Set.new(user_hood_ids).any?(Set.new(sa_hood_ids))

    # is the only way this user is tied to this partner through the address?
    any_service_areas == false
  end

  # Destroy the partner's address in a transaction.
  # @return [void]
  def clear_address!
    Partner.transaction do
      old_address = address
      update! address_id: nil

      old_address&.destroy
    end
  end

  # @return [String, nil] full Twitter profile URL
  def twitter_url
    "https://twitter.com/#{twitter_handle}" if twitter_handle.present?
  end

  # @return [String, nil] full Instagram profile URL
  def instagram_url
    "https://instagram.com/#{instagram_handle}" if instagram_handle.present?
  end

  # @return [String, nil] CarrierWave image URL
  def logo_url
    image&.url
  end

  # @return [Integer] number of events starting this week
  def events_this_week
    events.find_by_week(Time.now).count
  end

  # @return [String] JSON string of opening times, or "[]" if blank/invalid
  def opening_times_data
    # FIXME: opening_times field is really just a string
    #  even tho we use jsonb as a field type. this should
    #  be corrected to just push raw object data into the
    #  field and let PG deal with it.
    return '[]' if opening_times.blank?
    return '[]' unless valid_json? opening_times

    opening_times
  end

  # @return [Array<String>] HTML-safe strings like "Monday 9:00am – 5:00pm"
  def human_readable_opening_times
    return [] if !opening_times || opening_times.length.zero?

    JSON.parse(opening_times).map do |s|
      d = s['dayOfWeek'].split('/').last
      o = Time.parse(s['opens']).strftime('%-l:%M%P')
      c = Time.parse(s['closes']).strftime('%-l:%M%P')
      %( <span class='opening_times--day'>#{d}</span>
         <span class='opening_times--time'>#{o} &ndash; #{c}</span>
      ).html_safe
    end
  rescue JSON::ParserError
    []
  end

  # @return [Boolean] whether public_phone passes format validation
  def valid_public_phone?
    self.class.validators_on(:public_phone).each do |validator|
      validator.validate_each(self, :public_phone, public_phone)
    end

    errors.blank?
  end

  # @return [Boolean] whether name passes format/length validation
  def valid_name?
    self.class.validators_on(:name).each do |validator|
      validator.validate_each(self, :name, name)
    end

    errors.blank?
  end

  # @return [Array<Integer>] neighbourhood IDs from address + service areas
  def owned_neighbourhood_ids
    neighbourhood_ids = service_areas.pluck(:neighbourhood_id)
    neighbourhood_ids << address.neighbourhood_id if address&.neighbourhood_id

    neighbourhood_ids
  end

  # @param badge_zoom_level [String] zoom level for badge display
  # @return [String, nil] neighbourhood name appropriate for the site's zoom
  def neighbourhood_name_for_site(badge_zoom_level)
    if service_areas.any?
      if service_areas.many?
        'Various'
      else
        service_areas.first&.neighbourhood&.shortname
      end
    else
      address&.neighbourhood&.name_from_badge_zoom(badge_zoom_level)
    end
  end

  private

  # ==== Private methods ====

  def refresh_neighbourhood_partners_count
    # Refresh count for current neighbourhood (via address)
    address&.neighbourhood&.refresh_partners_count!

    # If address_id changed, also refresh the old neighbourhood
    if previous_changes.key?('address_id')
      old_address_id = previous_changes['address_id'].first
      if old_address_id
        old_address = Address.find_by(id: old_address_id)
        old_address&.neighbourhood&.refresh_partners_count!
      end
    end
  end

  def neighbourhood_admin_address_access
    # we trust that the user who last updated the address has been vetted
    return if address.nil? || (address.present? && !address.changed?)

    # user has privileged access
    return if accessed_by_user.nil? || accessed_by_user.root?

    # access granted based on partner relation not place relation == more trust
    return if accessed_by_user.admin_for_partner?(id)

    if persisted? # It's an update
      unless accessed_by_user.assigned_to_postcode?(address&.postcode)
        errors.add :base, 'Partners cannot have an address outside of your ward.'
      end

    else # It's an create
      unless address.blank? || accessed_by_user.assigned_to_postcode?(address&.postcode)
        errors.add :base, 'Partners cannot have an address outside of your ward.'
      end
    end
  end

  def check_neighbourhood_access
    # skip this test if address has not changed
    return if address.present? && !address.changed?

    # skip this test if service areas have not changed
    return if service_areas.none?(&:changed?)

    return if accessed_by_user.nil? || accessed_by_user.root?
    return if accessed_by_user.admin_for_partner?(id)

    partner_service_areas = service_areas&.map(&:neighbourhood_id) || []
    user_neighbourhoods = accessed_by_user.owned_neighbourhood_ids

    in_user_neighbourhood = accessed_by_user.assigned_to_postcode?(address&.postcode)
    services_user_neighbourhood =
      Set.new(user_neighbourhoods).superset?(Set.new(partner_service_areas)) &&
      partner_service_areas.any?

    return if in_user_neighbourhood || services_user_neighbourhood

    errors.add :base, 'Partners must have an address or a service area inside your neighbourhood'
  end

  def check_remove_service_area(service_area_to_remove)
    return if accessed_by_user.nil? || accessed_by_user.root?
    return if accessed_by_user.admin_for_partner?(id)

    partner_service_areas = service_areas&.map(&:neighbourhood_id) || []
    new_service_areas = partner_service_areas.reject { |e| e == service_area_to_remove.neighbourhood_id }
    user_neighbourhoods = accessed_by_user.owned_neighbourhood_ids

    in_user_neighbourhood = accessed_by_user.assigned_to_postcode?(address&.postcode)
    services_user_neighbourhood = new_service_areas.present?

    return if in_user_neighbourhood || services_user_neighbourhood

    errors.add :service_areas, 'Partners must have an address or a service area inside your neighbourhood'
    throw :abort
  end

  def must_have_address_or_service_area
    return if service_areas.any? || address.present?

    errors.add :base, 'Partners must have at least one of service area or address'
  end

  def unix_updated_at
    updated_at.to_time.to_i
  end

  def valid_json?(json)
    JSON.parse(json)
    true
  rescue JSON::ParserError, TypeError => _e
    false
  end

  def opening_times_is_json_or_nil
    return if valid_json? opening_times
    return if opening_times.nil?

    errors.add :base, 'Partner.opening_times must be valid json'
  end

  def three_or_less_category_tags
    # we can't just use categories.count here because of STI, on create they won't exist yet
    return if category_ids.count <= MAX_CATEGORIES

    errors.add :categories, "Partners can have a maximum of #{MAX_CATEGORIES} Category tags"
  end

  def partnership_admins_must_add_partnership
    return if accessed_by_user.nil? # HACK: to stop factory breaking tests
    return unless accessed_by_user.partnership_admin?

    if partnership_ids.any?
      accessed_by_user.tags.pluck(:id).each do |t|
        return true if partnership_ids.include? t
      end
    end

    errors.add :base, 'This partner must be a part of your partnership'
  end

  def must_give_reason_to_hide
    return unless hidden
    return if hidden && hidden_reason.present?

    errors.add :base, 'You need to give a reason for hiding a Partner from all public sites, this will help them resolve the issue.'
  end

  def must_record_who_has_hidden
    return unless hidden
    return if hidden && hidden_blame_id.present?

    errors.add :base, 'You must record who has hidden the partner'
  end
end
