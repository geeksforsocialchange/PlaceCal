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
    repeating = args[:repeating] || 'on'
    events = place ? Event.in_place(place) : Event.all
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
        if o.class == Place && o&.address&.latitude
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
end
