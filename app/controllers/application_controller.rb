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
    params[:sort].to_s if params[:sort]
  end

  def filter_events(period, place = false)
    events = place ? Event.in_place(place) : Event.all
    case period
    when 'week'
      events.find_by_week(@current_day).includes(:place)
    else
      events.find_by_day(@current_day).includes(:place)
    end
  end

  def sort_events(events, sort)
    case sort
    when 'summary'
      events.sort_by_summary
    else
      events.sort_by_time
    end
  end
end
