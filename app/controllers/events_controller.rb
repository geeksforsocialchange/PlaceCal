# frozen_string_literal: true

# app/controllers/events_controller.rb
class EventsController < ApplicationController
  include MapMarkers

  before_action :set_event, only: %i[show edit update destroy]
  before_action :set_day, only: :index
  before_action :set_sort, only: :index
  before_action :set_primary_neighbourhood, only: :index
  before_action :set_site
  before_action :redirect_from_default_site

  # GET /events
  # GET /events.json
  def index
    # Duration to view - default to day view
    @period = params[:period].to_s || 'day'
    @repeating = params[:repeating] || 'on'
    @neighbourhood_id = current_neighbourhood

    all_site_events = filter_events(site: current_site)
    @neighbourhood_filter = NeighbourhoodFilter.new(
      neighbourhoods_from(all_site_events),
      params
    )

    @events = sort_events(
      filter_events(
        @period,
        repeating: @repeating,
        site: current_site,
        neighbourhood_id: @neighbourhood_id
      ), @sort
    )

    respond_to do |format|
      format.html do
        if params[:simple].present?
          render :index_simple, layout: false
        else
          render :index
        end
      end
      format.text
      format.ics do
        # TODO: Add caching maybe Rails.cache.fetch(:ics, expires_in: 1.hour)?
        ics_listing = Event.ical_feed
        cal = create_calendar(ics_listing)
        cal.publish
        render plain: cal.to_ical
      end
    end
  end

  def ical; end

  # GET /events/1
  # GET /events/1.json
  def show
    if @event.place
      @map = get_map_markers([@event.place])
    elsif @event.address
      @map = get_map_markers([@event.address])
    end
    respond_to do |format|
      format.html
      format.ics do
        cal = create_calendar([@event])
        cal.publish
        render plain: cal.to_ical
      end
    end
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit; end

  # POST /events
  # POST /events.json
  def create
    @event = Event.new(event_params)

    respond_to do |format|
      if @event.save
        format.html { redirect_to @event, notice: 'Event was successfully created.' }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1
  # PATCH/PUT /events/1.json
  def update
    default_update(@event, event_params)
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    @event.destroy
    respond_to do |format|
      format.html { redirect_to events_url, notice: 'Event was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_event
    @event = Event.find(params[:id])
  end

  # Never trust parameters from the scary internet
  def event_params
    params.fetch(:event, {})
  end

  def current_neighbourhood
    params.fetch(:neighbourhood, '').presence
  end

  def neighbourhoods_from(events)
    all_event_neighbourhoods =
      events.each_with_object(Set[]) do |event, neighbourhoods|
        neighbourhoods << event.neighbourhood if event.neighbourhood
      end
    all_event_neighbourhoods.to_a.sort_by(&:name)
  end
end
