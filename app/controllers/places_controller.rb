# frozen_string_literal: true

# app/controllers/places_controller.rb
class PlacesController < ApplicationController
  before_action :set_place, only: %i[show embed]
  before_action :set_day, only: %i[show embed]
  before_action :set_sort, only: :show

  def index
    @places = Place.order(:name)
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

  def new
    @place = Place.new
  end

  def edit; end

  def create
    @place = Place.new(place_params)

    respond_to do |format|
      if @place.save
        format.html { redirect_to @place, notice: 'Place was successfully created.' }
        format.json { render :show, status: :created, location: @place }
      else
        format.html { render :new }
        format.json { render json: @place.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    default_update(@place, place_params)
  end

  private

end
