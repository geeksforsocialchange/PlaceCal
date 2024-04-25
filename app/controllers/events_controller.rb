# frozen_string_literal: true

# app/controllers/events_controller.rb
class EventsController < ApplicationController
  include MapMarkers

  before_action :set_event, only: %i[show]
  before_action :set_day, only: :index
  before_action :set_sort, only: :index
  before_action :set_primary_neighbourhood, only: :index
  before_action :set_site
  before_action :redirect_from_default_site

  # GET /events
  # GET /events.json
  def index
    # Duration to view - default to future view
    @period = params[:period] || 'future'
    @repeating = params[:repeating] || 'on'
    @events = filter_events(@period, repeating: @repeating, site: current_site)
    # Duration to view - default to day view if there are too many future events
    if params[:period].to_s == '' && @events.count > 200
      @period = 'week'
      @events = filter_events(@period, repeating: @repeating, site: current_site)
    end
    @title = current_site.name
    # Sort criteria
    @events = sort_events(@events, @sort)
    @multiple_days = true

    @next = if params[:year]
              date = begin
                Date.new(params[:year].to_i,
                         params[:month].to_i,
                         params[:day].to_i)
              rescue Date::Error
                Time.zone.today
              end
              Event.for_site(current_site).future(
                date
              ).first
            else
              Event.for_site(current_site).future(
                Time.zone.today
              ).first
            end

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
        events = Event.all
        events = events.for_site(@site) if @site
        # TODO: Add caching maybe Rails.cache.fetch(:ics, expires_in: 1.hour)?
        ics_listing = events.ical_feed
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
    if @event.partner_at_location
      @map = get_map_markers([@event.partner_at_location])
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

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_event
    @event = Event.find(params[:id])
  end
end
