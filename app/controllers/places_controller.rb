# frozen_string_literal: true

# app/controllers/places_controller.rb
class PlacesController < ApplicationController
  before_action :set_place, only: %i[show embed]
  before_action :set_day, only: %i[show embed]
  before_action :set_sort, only: :show
  before_action :set_home_turf, only: [:index]

  def index
    if current_site
      # Only get those places relevant to the requested site.
      @places = Place.joins(:address).where( addresses: { neighbourhood_turf: current_site.turfs } )
    else # this is the canonical site.
      @places = Place.order(:name)
    end

    @map = generate_points(@places)
  end

  def show
    # Period to show
    @period = params[:period] || 'week'
    @events = filter_events(@period, place: @place)
    # Sort criteria
    @sort = params[:sort].to_s || 'time'
    @events = sort_events(@events, @sort)
    # Map
    @map = generate_points([@place])

    respond_to do |format|
      format.html
      format.ics do
        cal = create_calendar(Event.in_place(@place).ical_feed, "#{@place} - Powered by PlaceCal")
        cal.publish
        render plain: cal.to_ical
      end
    end
  end

  def embed
    period = params[:period] || 'week'
    limit = params[:limit] || '10'
    @events = filter_events(period, place: @place, limit: limit)
    @events = sort_events(@events, 'time')
    response.headers.except! 'X-Frame-Options'
    render layout: false
  end

  private
end
