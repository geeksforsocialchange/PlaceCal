# frozen_string_literal: true

# app/components/event/event_component.rb
class EventComponent < MountainView::Presenter
  properties :summary, :description, :dtstart, :dtend,
             :location, :context, :place

  include ActionView::Helpers::TextHelper

  def time
    fmt_time(dtstart) + ' – ' + fmt_time(dtend)
  end

  def duration
    mins = ((dtend - dtstart) / 60).to_i
    hours = mins / 60 # Ruby presumes ints not floats, and rounds down
    mins_str = (mins % 60).positive? ? "#{mins % 60} mins" : ''
    hours_str = hours.positive? ? pluralize(hours, 'hour') : ''
    [hours_str, mins_str].reject(&:empty?).join(' ')
  end

  def date
    dtstart.strftime('%e %b')
  end

  def summary
    properties[:summary]
  end

  def description
    properties[:description]
  end

  def page?
    properties[:context] == :page
  end

  def partner
    properties[:partner].first
  end

  def location
    properties[:location].split(',').first&.delete('\\')
  end

  def repeats
    properties[:rrule].present? ? properties[:rrule][0]['table']['frequency'].titleize : false
  end

  private

  def fmt_time(time)
    if time.strftime('%M') == '00'
      time.strftime('%l%P')
    else
      time.strftime('%l:%M%P')
    end
  end

  def dtstart
    properties[:dtstart]
  end

  def dtend
    properties[:dtend]
  end
end
