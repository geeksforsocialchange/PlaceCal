# frozen_string_literal: true

# app/models/partner.rb
class Partner < ApplicationRecord
  include Validation

  extend FriendlyId
  friendly_id :name, use: :slugged

  include HtmlRenderCache
  html_render_cache :description
  html_render_cache :summary
  html_render_cache :accessibility_info

  # Associations
  has_and_belongs_to_many :users
  has_many :calendars, dependent: :destroy
  has_many :events
  belongs_to :address, optional: true

  has_many :partner_tags, dependent: :destroy
  has_many :tags, through: :partner_tags

  has_many :service_areas, dependent: :destroy
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
                          foreign_key: 'subject_id',
                          association_foreign_key: 'object_id'

  has_and_belongs_to_many :subjects,
                          class_name: 'Partner',
                          join_table: :organisation_relationships,
                          foreign_key: 'object_id',
                          association_foreign_key: 'subject_id'

  accepts_nested_attributes_for :calendars, allow_destroy: true

  accepts_nested_attributes_for :address, reject_if: ->(c) { c[:postcode].blank? && c[:street_address].blank? }

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
              if: ->(p) { !p.description.blank? },
              message: 'cannot have a description without a summary'
            }
  validates :url,
            format: { with: URL_REGEX, message: 'is invalid' },
            allow_blank: true
  validates :twitter_handle,
            format: { with: TWITTER_REGEX, message: 'invalid account name' },
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

  validates_associated :address

  validate :check_ward_access, on: :create
  validate :check_service_area_access, on: :create

  validate :must_have_address_or_service_area, on: :create

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
  # If the site has tags, the list of partners will be filtered by those tags
  #
  # @param site [Site] The site we want partners for.
  # @return [ActiveRecord::Relation<Partner>]
  scope :for_site, lambda { |site|
    site_neighbourhood_ids = site.owned_neighbourhoods.map(&:id)

    site_tag_ids = site.tags.map(&:id)
    partners = from_neighbourhoods_and_service_areas(site_neighbourhood_ids)

    site_tag_ids.any? ? partners.with_tags(site_tag_ids) : partners
  }

  # Get a list of Partners that have the given tags
  #
  # @param tags [Array<Tag>] A list of tags
  # @return [ActiveRecord::Relation<Partner>]
  scope :with_tags, ->(tags) { joins(:partner_tags).where(partner_tags: { tag: tags }) }

  # only select partners that have addresses
  scope :with_address, -> do
    where('address_id is not null')
  end

  # Get all Partners that have hosted an event in the last month or will host
  # an event in the future
  #
  # TODO? This might be an incredibly inefficient query. If so, add a column
  # to the Partner table, e.g. place_latest_dtstart, which can be updated on
  # import.
  scope :event_hosts, -> do
    joins('JOIN events ON events.place_id = partners.id')
      .where('events.dtstart > ?', Date.today - 30).distinct
  end

  # Get all Partners that manage at least one other Partner.
  scope :managers, -> do
    joins('JOIN organisation_relationships o_r on o_r.subject_id = partners.id')
      .where(o_r: { verb: :manages }).distinct
  end

  delegate :neighbourhood_id, to: :address, allow_nil: true

  def twitter_handle=(handle)
    super(handle&.gsub('@', ''))
  end

  def address_attributes=(value)
    addr = Address
      .where('lower(street_address) = ?', value[:street_address]&.downcase&.strip)
      .where(postcode: value[:postcode]&.upcase&.strip)
      .first

    if addr.present?
      self.address = addr
    else
      super
    end
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
    service_areas.count > 0
  end

  def permalink
    "https://placecal.org/partners/#{id}"
  end

  def twitter_url
    "https://twitter.com/#{twitter_handle}" if twitter_handle.present?
  end

  def logo_url
    image_url(image.url, skip_pipeline: true) if image.present?
  end

  # Get a count of all the events this week
  def events_this_week
    events.find_by_week(Time.now).count
  end

  def human_readable_opening_times
    return [] if !opening_times || opening_times.length == 0

    JSON.parse(opening_times).map do |s|
      d = s['dayOfWeek'].split('/').last
      o = Time.parse(s['opens']).strftime('%-l:%M%P')
      c = Time.parse(s['closes']).strftime('%-l:%M%P')
      %( <span class='opening_times--day'>#{d}</span>
         <span class='opening_times--time'>#{o} &ndash; #{c}</span>
      ).html_safe
    end
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

  def self.fuzzy_find_by_location(components)
    Partner.find_by('lower(name) IN (?)', components.map(&:downcase))
  end

  private

  def check_ward_access
    return if accessed_by_user.nil? || accessed_by_user.root?
    return unless address.present?

    unless accessed_by_user.assigned_to_postcode?(address&.postcode)
      errors.add :base, 'Partners cannot have an address outside of your ward.'
    end
  end

  def check_service_area_access
    return if accessed_by_user.nil? || accessed_by_user.root?

    my_neighbourhoods = service_areas.map(&:neighbourhood_id)
    return if my_neighbourhoods.empty?

    user_neighbourhoods = accessed_by_user.owned_neighbourhood_ids

    partner_neighbourhoods_set = Set.new(my_neighbourhoods)
    user_neighbourhoods_set = Set.new(user_neighbourhoods)

    unless user_neighbourhoods_set.superset?(partner_neighbourhoods_set)
      errors.add :base, 'Partners cannot have a service area outside of your ward.'
    end
  end

  def must_have_address_or_service_area
    return if service_areas.any? || address.present?

    errors.add :base, 'Partners must have at least one of service area or address'
  end

  def unix_updated_at
    updated_at.to_time.to_i
  end
end
