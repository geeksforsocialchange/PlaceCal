# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  # Set the day either using the URL or by today's date
  def set_day
    @today = Date.today
    day = params[:day] || 1
    @current_day =
      if params[:year] && params[:month] && day
        Date.new(params[:year].to_i,
                 params[:month].to_i,
                 params[:day].to_i)
      else
        @today
      end
  end

  def set_sort
    @sort = params[:sort].to_s ? params[:sort] : false
  end

  def filter_events(period, **args)
    place     = args[:place]     || false
    partner   = args[:partner]   || false
    repeating = args[:repeating] || 'on'
    events = place ? Event.in_place(place) : Event.all
    events = events.by_partner(partner) if partner
    events = events.one_off_events_only if repeating == 'off'
    events = events.one_off_events_first if repeating == 'last'
    events =
      if period == 'week'
        events.find_by_week(@current_day).includes(:place)
      else
        events.find_by_day(@current_day).includes(:place)
      end
    args[:limit] ? events.limit(limit) : events
  end

  def sort_events(events, sort)
    if sort == 'summary'
      [[Time.now, events.sort_by_summary]]
    else
      events.sort_by_time.group_by_day(&:dtstart)
    end
  end

  # Takes an array of places or addresses and returns a sanitized json array
  def generate_points(obj)
    obj.reduce([]) do |arr, o|
      arr <<
        if ([Place, Partner].include? o.class) && (o&.address&.latitude)
          {
            lat: o.address.latitude,
            lon: o.address.longitude,
            name: o.name,
            id: o.id
          }
        elsif o.class == Address
          {
            lat: o.latitude,
            lon: o.longitude
          }
        end
    end
  end

  # Create a calendar from array of events
  def create_calendar(events, title = false)
    cal = Icalendar::Calendar.new
    cal.x_wr_calname = title || 'PlaceCal: Hulme & Moss Side'
    events.each do |e|
      ical = create_ical_event(e)
      cal.add_event(ical)
    end
    cal
  end

  # TODO: Refactor this to a view or something
  # Convert an event object into an ics listing
  def create_ical_event(e)
    event = Icalendar::Event.new
    event.dtstart = e.dtstart
    event.dtend = e.dtend
    event.summary = e.summary
    event.description = e.description + "\n\n<a href='https://placecal.org/events/#{e.id}'>More information about this event on PlaceCal.org</a>"
    event.location = e.location
    event
  end
end
