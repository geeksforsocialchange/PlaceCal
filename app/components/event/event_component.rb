# frozen_string_literal: true

# app/components/event/event_component.rb
class EventComponent < MountainView::Presenter
  properties :context, :event, :primary_neighbourhood, :show_neighbourhoods, :badge_zoom_level

  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::DateHelper

  delegate :id, to: :event

  delegate :place, to: :event

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
    hours = mins / 60 # Ruby presumes ints not floats, and rounds down

    if hours < 25
      mins_str = (mins % 60).positive? ? "#{mins % 60} mins" : ''
      hours_str = hours.positive? ? pluralize(hours, 'hour') : ''
      [hours_str, mins_str].reject(&:empty?).join(' ')
    else
      distance_of_time_in_words event.dtend - event.dtstart
    end
  end

  def formatted_date(date)
    if date.year == Time.now.year
      date.strftime('%e %b')
    else
      date.strftime('%e %b %Y')
    end
  end

  def date
    if event.dtstart.to_date == event.dtend.to_date
      formatted_date(event.dtstart)
    else
      "#{formatted_date(event.dtstart)} - #{formatted_date(event.dtend)}"
    end
  end

  delegate :summary, to: :event

  delegate :description, to: :event

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

  def neighbourhood_name(badge_zoom_level)
    event.neighbourhood&.name_from_badge_zoom(badge_zoom_level)
  end

  def primary_neighbourhood?
    # Show everything as primary if primary is not set
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

  # Prevent method-access in erb file for named properties.

  def event
    properties[:event]
  end

  def context
    properties[:context]
  end
end
