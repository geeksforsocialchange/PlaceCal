# frozen_string_literal: true

class EventComponent < ViewComponent::Base
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::DateHelper
  include SvgIconsHelper

  # rubocop:disable Metrics/ParameterLists
  def initialize(context:, event:, primary_neighbourhood: nil, show_neighbourhoods: false, badge_zoom_level: nil, site_tagline: nil)
    # rubocop:enable Metrics/ParameterLists
    super()
    @context = context
    @event = event
    @primary_neighbourhood = primary_neighbourhood
    @show_neighbourhoods = show_neighbourhoods
    @badge_zoom_level = badge_zoom_level
    @site_tagline = site_tagline
  end

  attr_reader :context, :event, :primary_neighbourhood, :show_neighbourhoods, :badge_zoom_level, :site_tagline

  delegate :id, to: :event
  delegate :partner_at_location, to: :event
  delegate :summary, to: :event
  delegate :description, to: :event

  def time
    if event.dtend
      "#{fmt_time(event.dtstart)} – #{fmt_time(event.dtend)}"
    else
      fmt_time(event.dtstart)
    end
  end

  def duration
    return false unless event.dtend

    mins = ((event.dtend - event.dtstart) / 60).to_i
    hours = mins / 60

    if hours < 25
      mins_str = (mins % 60).positive? ? "#{mins % 60} mins" : ''
      hours_str = hours.positive? ? pluralize(hours, 'hour') : ''
      [hours_str, mins_str].reject(&:empty?).join(' ')
    else
      distance_of_time_in_words event.dtend - event.dtstart
    end
  end

  def formatted_date(date)
    if date.year == Time.zone.now.year
      date.strftime('%e %b')
    else
      date.strftime('%e %b %Y')
    end
  end

  def date
    return formatted_date(event.dtstart) if event.dtend.blank?

    if event.dtstart.to_date == event.dtend.to_date
      formatted_date(event.dtstart)
    else
      "#{formatted_date(event.dtstart)} - #{formatted_date(event.dtend)}"
    end
  end

  def page?
    context == :page
  end

  def partner
    event.partner.first
  end

  def first_address_line
    event.address&.street_address&.delete('\\')
  end

  def repeats
    event.rrule.present? ? event.rrule[0]['table']['frequency'].titleize : false
  end

  def neighbourhood_name
    event.neighbourhood&.name_from_badge_zoom(badge_zoom_level)
  end

  def primary_neighbourhood?
    return true unless primary_neighbourhood

    event.neighbourhood == primary_neighbourhood || primary_neighbourhood.children.include?(event.neighbourhood)
  end

  def online?
    event.online_address.present?
  end

  private

  def fmt_time(time)
    if time.strftime('%M') == '00'
      time.strftime('%l%P')
    else
      time.strftime('%l:%M%P')
    end
  end
end
