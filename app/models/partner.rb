# frozen_string_literal: true

# app/models/partner.rb
class Partner < ApplicationRecord
  after_initialize :set_defaults, unless: :persisted?
  include Validation

  extend FriendlyId
  friendly_id :name, use: :slugged

  include HtmlRenderCache
  html_render_cache :description
  html_render_cache :summary
  html_render_cache :accessibility_info
  html_render_cache :hidden_reason

  # Associations
  has_and_belongs_to_many :users
  has_many :calendars, dependent: :destroy
  has_many :events
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

  validates_associated :service_areas

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
    [c[:city].blank?,
     c[:postcode].blank?,
     c[:street_address].blank?,
     c[:street_address2].blank?,
     c[:street_address3].blank?].all?
  }

  validates_associated :address

  accepts_nested_attributes_for :service_areas, allow_destroy: true

  # Validations
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

  validate :check_neighbourhood_access

  validate :neighbourhood_admin_address_access, on: %i[create update]

  validate :must_have_address_or_service_area

  validate :opening_times_is_json_or_nil

  validate :three_or_less_category_tags

  validate :partnership_admins_must_add_tag, on: %i[create]

  validate :must_give_reason_to_hide

  validate :must_record_who_has_hidden

  attr_accessor :accessed_by_user

  mount_uploader :image, ImageUploader

  scope :recently_updated, -> { order(updated_at: desc) }

  # Takes in a list of neighbourhood ids, and returns a list of Partners
  # that 'own' those neighbourhoods, either as Service Areas or as Addresses
  #
  # @param ids [Array<Int>] A list of neighbourhood ids
  # @return [ActiveRecord::Relation<Partner>]
  scope :from_neighbourhoods_and_service_areas, lambda { |ids|
    left_joins(:address, :service_areas)
      .where('(service_areas.neighbourhood_id in (?)) or (addresses.neighbourhood_id in (?))',
             ids, ids)
  }

  # Takes in a Site and fetches all Partners for that site
  #   In its basic mode (without tags) it looks for partners by address
  #   or service area and returns a distinct set (as a partner can
  #   have many service areas or an address that overlaps).
  #   If the site has tags present then the filter is constrained to
  #   only allow partners that have had that tag applied (and then the
  #   same rule applies as above).
  #   If no site tags exist then skip that part of the query. If no
  #   site neighbourhoods exist then return an empty scope
  #
  # @param site [Site] The site we want partners for.
  # @return [ActiveRecord::Relation<Partner>]
  scope :for_site, lambda { |site|
    query = Partner

    # if site has tags show only partners WITH those tags
    site_tag_ids = site.tags.map(&:id)
    if site_tag_ids.any?
      query = query
              .left_joins(:partner_tags)
              .where('partner_tags.tag_id in (?)', site_tag_ids)
    end

    # now look for addresses and service areas
    site_neighbourhood_ids = site.owned_neighbourhood_ids

    # skip everything if site has no neighbourhoods
    return none if site_neighbourhood_ids.empty?

    query
      .left_joins(:address, :service_areas)
      .where(
        'NOT hidden AND (service_areas.neighbourhood_id in (:neighbourhood_ids) OR addresses.neighbourhood_id in (:neighbourhood_ids))',
        neighbourhood_ids: site_neighbourhood_ids
      )
      .distinct
  }

  scope :for_site_with_tag, lambda { |site, tag|
    return none if tag.nil?

    query = Partner
            .select('"partners".*, LOWER("partners"."name") as sortable_name')

    query = query
            .left_joins(:partner_tags)
            .where(partner_tags: { tag: tag })

    # now look for addresses and service areas
    site_neighbourhood_ids = site.owned_neighbourhood_ids

    # skip everything if site has no neighbourhoods
    return none if site_neighbourhood_ids.empty?

    # TODO; move this scope part that is very similar to the `for_site` method above
    #   into a shared scope (with possible tests)
    query
      .left_joins(:address, :service_areas)
      .where(
        'NOT hidden AND (service_areas.neighbourhood_id in (:neighbourhood_ids) OR addresses.neighbourhood_id in (:neighbourhood_ids))',
        neighbourhood_ids: site_neighbourhood_ids
      )
      .distinct
      .order('sortable_name')
  }

  # Get a list of Partners that have the given tags
  #
  # @param tags [Array<Tag>] A list of tags
  # @return [ActiveRecord::Relation<Partner>]
  scope :with_tags, lambda { |tag_ids|
    left_joins(:partner_tags)
      .where('partner_tags.tag_id in (?)', tag_ids)
  }

  # only select partners that have addresses
  scope :with_address, lambda {
    where.not(address_id: nil)
  }

  # Get all Partners that have hosted an event in the last month or will host
  # an event in the future
  #
  # TODO? This might be an incredibly inefficient query. If so, add a column
  # to the Partner table, e.g. place_latest_dtstart, which can be updated on
  # import.
  scope :event_hosts, lambda {
    joins('JOIN events ON events.place_id = partners.id')
      .where('events.dtstart > ?', Date.today - 30).distinct
  }

  # Get all Partners that manage at least one other Partner.
  scope :managers, lambda {
    joins('JOIN organisation_relationships o_r on o_r.partner_subject_id = partners.id')
      .where(o_r: { verb: :manages }).distinct
  }

  delegate :neighbourhood_id, to: :address, allow_nil: true

  def twitter_handle=(handle)
    super(handle&.gsub('@', ''))
  end

  # Get all Partners that manage this Partner.
  def managers
    subjects.where(organisation_relationships: { verb: :manages })
  end

  # Get all Partners that this Partner manages.
  def managees
    objects.where(organisation_relationships: { verb: :manages })
  end

  def to_s
    name
  end

  # def custom_validation_method_with_message
  #   errors.add(:_, "Select at least one Tag") if tag_ids.blank?
  # end

  def should_generate_new_friendly_id?
    slug.blank?
  end

  def has_service_areas?
    service_areas.any?
  end

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

  def clear_address!
    Partner.transaction do
      old_address = address
      update! address_id: nil

      old_address&.destroy
    end
  end

  def permalink
    "https://placecal.org/partners/#{id}"
  end

  def twitter_url
    "https://twitter.com/#{twitter_handle}" if twitter_handle.present?
  end

  def logo_url
    image&.url
  end

  # Get a count of all the events this week
  def events_this_week
    events.find_by_week(Time.now).count
  end

  def opening_times_data
    # FIXME: opening_times field is really just a string
    #  even tho we use jsonb as a field type. this should
    #  be corrected to just push raw object data into the
    #  field and let PG deal with it.
    return '[]' if opening_times.blank?
    return '[]' unless valid_json? opening_times

    opening_times
  end

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

  def valid_public_phone?
    self.class.validators_on(:public_phone).each do |validator|
      validator.validate_each(self, :public_phone, public_phone)
    end

    errors.blank?
  end

  def valid_name?
    self.class.validators_on(:name).each do |validator|
      validator.validate_each(self, :name, name)
    end

    errors.blank?
  end

  # @return [Array<Int>] A list of Neighbourhood IDs
  def owned_neighbourhood_ids
    neighbourhood_ids = service_areas.pluck(:neighbourhood_id)
    neighbourhood_ids << address.neighbourhood_id if address&.neighbourhood_id

    neighbourhood_ids
  end

  def neighbourhood_name_for_site(badge_zoom_level)
    if service_areas.any?
      if service_areas.count > 1
        'Various'
      else
        service_areas.first&.neighbourhood&.shortname
      end
    else
      address&.neighbourhood&.name_from_badge_zoom(badge_zoom_level)
    end
  end

  def self.fuzzy_find_by_location(components)
    Partner.find_by('lower(name) IN (?)', components.map(&:downcase))
  end

  def self.neighbourhood_names_for_site(current_site, badge_zoom_level)
    partners = Partner.for_site(current_site)
                      .includes(:service_areas, :address)
    partner_names = []
    partners.each do |partner|
      name = partner.neighbourhood_name_for_site(badge_zoom_level)
      partner_names << name if name.present?
    end
    partner_names.uniq.sort
  end

  def self.for_neighbourhood_name_filter(partners, badge_zoom_level, neighbourhood_name)
    partners_with_name = []
    partners.each do |partner|
      partners_with_name << partner if partner.neighbourhood_name_for_site(badge_zoom_level) == neighbourhood_name
    end
    partners_with_name.sort_by(&:name)
  end

  private

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
  rescue JSON::ParserError, TypeError => e
    false
  end

  def opening_times_is_json_or_nil
    return if valid_json? opening_times
    return if opening_times.nil?

    errors.add :base, 'Partner.opening_times must be valid json'
  end

  def three_or_less_category_tags
    # we can't just use categories.count here because of STI, on create they won't exist yet
    return if category_ids.count < 4

    errors.add :categories, 'Partners can have a maximum of 3 Category tags'
  end

  def partnership_admins_must_add_tag
    return if accessed_by_user.nil? # HACK: to stop factory breaking tests
    return unless accessed_by_user.partnership_admin?

    if tags.any?
      accessed_by_user.tags.each do |t|
        return true if tags.include? t
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

  def set_defaults
    self.hidden ||= false
  end
end
