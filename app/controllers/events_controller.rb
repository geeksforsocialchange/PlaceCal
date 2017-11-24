# app/controllers/events_controller.rb
class EventsController < ApplicationController
  before_action :set_event, only: %i[show edit update destroy]
  before_action :set_day, only: :index
  before_action :set_sort, only: :index

  # GET /events
  # GET /events.json
  def index
    # Duration to view - default to day view
    @period = params[:period].to_s || 'day'
    @repeating = params[:repeating] || 'on'
    @events = filter_events(@period, repeating: @repeating)
    # Sort criteria
    @events = sort_events(@events, @sort)
    @multiple_days = true

    respond_to do |format|
      format.html
      format.ics do
        # TODO: Add caching maybe Rails.cache.fetch(:ics, expires_in: 1.hour)?
        # TODO: Refactor this entire monstrosity
        ics = Event.ical_feed
        cal = Icalendar::Calendar.new
        cal.x_wr_calname = 'PlaceCal: Hulme & Moss Side'
        ics.each do |e|
          event = Icalendar::Event.new
          event.dtstart = e.dtstart
          event.dtend = e.dtend
          event.summary = e.summary
          event.description = e.description + "\n\n<a href='https://placecal.org/events/#{e.id}'>More information about this event on PlaceCal</a>"
          event.location = e.location
          cal.add_event(event)
        end
        cal.publish
        render plain: cal.to_ical
      end
    end
  end

  def ical
  end

  # GET /events/1
  # GET /events/1.json
  def show
    @map = generate_points([@event.place]) if @event.place
    respond_to do |format|
      format.html
      format.ics do
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
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to @event, notice: 'Event was successfully updated.' }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
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
end
