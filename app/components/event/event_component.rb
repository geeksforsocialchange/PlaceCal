# app/components/header/header_component.rb
class EventComponent < MountainView::Presenter
  properties :summary, :description, :dtstart, :dtend, :location, :context, :place

  def dtstart
    case context
    when :day
      properties[:dtstart].strftime("%H:%M")
    else
      properties[:dtstart].strftime("%a %e %b, %H:%M")
    end
  end

  def dtend
    properties[:dtstart].strftime("%H:%M")
  end

end
