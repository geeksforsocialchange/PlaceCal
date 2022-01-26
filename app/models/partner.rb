# frozen_string_literal: true

# app/models/partner.rb
class Partner < ApplicationRecord
  include Validation

  extend FriendlyId
  friendly_id :name, use: :slugged

  # Associations
  has_and_belongs_to_many :users
  has_and_belongs_to_many :tags, validate: true
  has_many :calendars, dependent: :destroy
  has_many :events
  belongs_to :address, optional: true

  has_many :service_areas, dependent: :destroy
  has_many :service_area_neighbourhoods,
    through: :service_areas,
    source: :neighbourhood,
    class_name: 'Neighbourhood'

  validates_associated :service_areas

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
              if: ->(p) { !p.description.nil? },
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


  validate :check_ward_access

  attr_accessor :accessed_by_id

  mount_uploader :image, ImageUploader

  scope :recently_updated, -> { order(updated_at: desc) }

  scope :for_site, ->(site) { joins(:address).where( addresses: { neighbourhood: site.neighbourhoods } ) }

  scope :of_tag, ->(tag) { joins(:partners_tags).where( partners_tags: { tag: tag } ) }

  # Get all Partners that have hosted an event in the last month or will host
  # an event in the future
  scope :event_hosts, -> do
    # TODO? This might be an incredibly inefficient query. If so, add a column
    # to the Partner table, e.g. place_latest_dtstart, which can be updated on
    # import.
    joins('JOIN events ON events.place_id = partners.id')
      .where('events.dtstart > ?', Date.today-30).distinct
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
    addr = Address.where('lower(street_address) = ?', value['street_address']&.downcase&.strip).first

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

  def permalink
    "https://placecal.org/partners/#{id}"
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

  private

  def check_ward_access
    user = User.where(id: accessed_by_id).first

    return if user.blank?

    unless user.assigned_to_postcode?(address&.postcode)
      errors.add(:base, 'Partners cannot be created outside of your ward.')
    end
  end
end
