# frozen_string_literal: true

# app/models/partner.rb
class Partner < ApplicationRecord
  URL_REGEX = /\A(?:(?:https?):\/\/)(?:\S+(?::\S*)?@)?(?:(?!10(?:\.\d{1,3}){3})(?!127(?:\.\d{1,3}){3})(?!169\.254(?:\.\d{1,3}){2})(?!192\.168(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,})))(?::\d{2,5})?(?:\/[^\s]*)?\z/i
  TWITTER_REGEX = /\A@?(\w){1,15}\z/
  FACEBOOK_REGEX = /\A(\w){1,15}\z/

  extend FriendlyId
  friendly_id :name, use: :slugged

  has_and_belongs_to_many :users
  has_and_belongs_to_many :turfs, validate: true
  has_many :calendars, dependent: :destroy
  has_many :events
  belongs_to :address, optional: true
  belongs_to :neighbourhood, optional: true

  has_and_belongs_to_many :objects,
  class_name: "Partner",
  join_table: :organisation_relationships,
  foreign_key: "subject_id",
  association_foreign_key: "object_id"

  has_and_belongs_to_many :subjects,
  class_name: "Partner",
  join_table: :organisation_relationships,
  foreign_key: "object_id",
  association_foreign_key: "subject_id"

  accepts_nested_attributes_for :calendars, allow_destroy: true

  accepts_nested_attributes_for :address, reject_if: ->(c) { c[:postcode].blank? && c[:street_address].blank? }

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false
  validates :name, length: { minimum: 5, too_short: 'must be at least 5 characters long' }
  validates :url, format: { with: URL_REGEX, message: 'is invalid' }, allow_blank: true
  validates :twitter_handle, format: { with: TWITTER_REGEX, message: 'invalid account name' }, allow_blank: true
  validates :facebook_link, format: { with: FACEBOOK_REGEX, message: 'invalid page name' }, allow_blank: true

  mount_uploader :image, ImageUploader

  after_save :update_users

  scope :recently_updated, -> { order(updated_at: desc) }

  scope :for_site, ->(site) { joins(:address).where( addresses: { neighbourhood: site.neighbourhoods } ) }

  scope :of_turf, ->(turf) { joins(:partners_turfs).where( partners_turfs: { turf: turf } ) }

  # Get all Partners that have hosted an event in the last month or will host
  # an event in the future
  scope :event_hosts, -> do
    # TODO? This might be an incredibly inefficient query. If so, add a column
    # to the Partner table, e.g. place_latest_dtstart, which can be updated on
    # import.
    joins("JOIN events ON events.place_id = partners.id")
    .where("events.dtstart > ?", Date.today-30).distinct
  end

  # Get all Partners that manage at least one other Partner.
  scope :managers, -> do
    joins("JOIN organisation_relationships o_r on o_r.subject_id = partners.id")
    .where(o_r: {verb: :manages}).distinct
  end

  # Get all Partners that manage this Partner.
  def managers
    subjects.where(organisation_relationships: {verb: :manages})
  end

  # Get all Partners that this Partner manages.
  def managees
    objects.where(organisation_relationships: {verb: :manages})
  end

  def to_s
    name
  end

  # def custom_validation_method_with_message
  #   errors.add(:_, "Select at least one Turf") if turf_ids.blank?
  # end

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

  private

  def update_users
    users.each(&:update_role)
  end
end
