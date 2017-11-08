# frozen_string_literal: true

# app/controllers/places_controller.rb
class PlacesController < ApplicationController
  before_action :set_place, only: %i[show edit update destroy]
  before_action :set_day, only: :show
  before_action :set_sort, only: :show

  # GET /places
  # GET /places.json
  def index
    @places = Place.order(:name)
    @map = @places.map do |p|
      next unless p.address && p.address.latitude
      {
        lat: p.address.latitude,
        lon: p.address.longitude,
        name: p.name,
        id: p.id
      }
    end
  end

  # GET /places/1
  # GET /places/1.json
  def show
    # Period to show
    @period = params[:period] || 'week'
    events = filter_events(@period, place: @place)
    # Sort criteria
    @sort = params[:sort].to_s || 'time'
    @events = sort_events(events, @sort)
    # Map
    @map = if @place&.address&.latitude
             [{
               lat: @place.address.latitude,
               lon: @place.address.longitude,
               name: @place.name,
               id: @place.id
             }]
           else
             []
           end
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
    @place = Place.find(params[:id])
  end

  # Never trust parameters from the scary internet
  def place_params
    params.fetch(:place, {})
  end
end
