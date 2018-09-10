# frozen_string_literal: true

# app/components/event/event_component.rb
class EventComponent < MountainView::Presenter
  properties :context, :event

  include ActionView::Helpers::TextHelper

  def id
    event.id
  end

  def place
    event.place
  end

  def location
    event.location
  end

  def time
    if event.dtend
      fmt_time(event.dtstart) + ' – ' + fmt_time(event.dtend)
    else
      fmt_time(event.dtstart)
    end
  end

  def duration
    return false unless event.dtend
    mins = ((event.dtend - event.dtstart) / 60).to_i
    hours = mins / 60 # Ruby presumes ints not floats, and rounds down
    mins_str = (mins % 60).positive? ? "#{mins % 60} mins" : ''
    hours_str = hours.positive? ? pluralize(hours, 'hour') : ''
    [hours_str, mins_str].reject(&:empty?).join(' ')
  end

  def date
    event.dtstart.strftime('%e %b')
  end

  def summary
    event.summary
  end

  def description
    event.description
  end

  def page?
    context == :page
  end

  def partner
    event.partner.first
  end

  def location
    event.location&.split(',')&.first&.delete('\\')
  end

  def repeats
    event.rrule.present? ? event.rrule[0]['table']['frequency'].titleize : false
  end

  def admin_ward
    event.admin_ward
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
