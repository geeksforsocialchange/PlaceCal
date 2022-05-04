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

  # Defines the strategy this Calendar uses to assign events to locations.
  # @attr [Enumerable<Symbol>] :strategy
  enumerize(
    :strategy,
    in: %i[event place room_number event_override no_location],
    default: :place,
    scope: true
  )

  # We need a default location for some strategies
  def requires_default_location?
    %i[place room_number event_override].include? strategy.to_sym
  end

  # Output the calendar's name when it's requested as a string
  def to_s
    name
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

  def last_imported
    if last_import_at
      "Last imported #{time_ago_in_words(last_import_at)} ago"
    else
      'Never imported'
    end
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

  def update_notice_count
    self.notice_count = (notices || []).count if notices_changed?
  end

  def source_supported
    CalendarImporter::CalendarImporter.new(self).validate_feed
    self.is_working = true
    self.critical_error = nil

  rescue CalendarImporter::CalendarImporter::InaccessibleFeed, CalendarImporter::CalendarImporter::UnsupportedFeed => e
    critical_import_failure e, false
  end

  def critical_import_failure(error, save_now=true)
    self.critical_error = error
    self.is_working = false
    self.save if save_now
  end
end

