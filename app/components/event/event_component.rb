# frozen_string_literal: true

# app/components/event/event_component.rb
class EventComponent < MountainView::Presenter
  properties :summary, :description, :dtstart, :dtend,
             :location, :context, :place

  def dtstart
    case properties[:context]
    when :day
      properties[:dtstart].strftime('%H:%M')
    when :week
      properties[:dtstart].strftime('%a %H:%M')
    else
      properties[:dtstart].strftime('%a %e %b, %H:%M')
    end
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

  def dtend
    properties[:dtend].strftime('%H:%M')
  end

  def partner
    properties[:partner].first
  end

  def location
    properties[:location].split(',').first&.delete('\\')
  end

end
