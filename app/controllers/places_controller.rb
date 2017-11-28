# frozen_string_literal: true

# app/controllers/places_controller.rb
class PlacesController < ApplicationController
  before_action :set_place, only: %i[show edit update destroy embed]
  before_action :set_day, only: %i[show embed]
  before_action :set_sort, only: :show

  # GET /places
  # GET /places.json
  def index
    @places = Place.order(:name)
    @map = generate_points(@places)
  end

  # GET /places/1
  # GET /places/1.json
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

  # GET /places/new
  def new
    @place = Place.new
  end

  # GET /places/1/edit
  def edit; end

  # POST /places
  # POST /places.json
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

  # PATCH/PUT /places/1
  # PATCH/PUT /places/1.json
  def update
    respond_to do |format|
      if @place.update(place_params)
        format.html { redirect_to @place, notice: 'Place was successfully updated.' }
        format.json { render :show, status: :ok, location: @place }
      else
        format.html { render :edit }
        format.json { render json: @place.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /places/1
  # DELETE /places/1.json
  def destroy
    @place.destroy
    respond_to do |format|
      format.html { redirect_to places_url, notice: 'Place was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_place
    @place = Place.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet
  def place_params
    params.fetch(:place, {})
  end
end
