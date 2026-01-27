# frozen_string_literal: true

# app/controllers/events_controller.rb
class EventsController < ApplicationController
  include MapMarkers

  before_action :set_event, only: %i[show]
  before_action :set_day, only: :index
  before_action :set_primary_neighbourhood, only: :index
  before_action :set_site
  before_action :redirect_from_default_site

  # GET /events
  # GET /events.json
  def index
    @repeating = params[:repeating] || 'on'
    @sort = params[:sort] || 'time'
    @query = EventsQuery.new(site: current_site, day: @current_day)
    @period = params[:period] || default_period

    @events = @query.call(period: @period, repeating: @repeating, sort: @sort)
    @next_date = @query.next_event_after(@current_day)
    @title = current_site.name

    respond_to do |format|
      format.html do
        if params[:simple].present?
          render :index_simple, layout: false
        else
          render :index
        end
      end
      format.text
      format.ics { render_ical }
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

  def set_event
    @event = Event.find(params[:id])
  end

  # Auto-select period based on event count
  def default_period
    return params[:period] if params[:period].present?

    @query.future_count > 50 ? 'week' : 'future'
  end

  def render_ical
    events = Event.all
    events = events.for_site(@site) if @site
    ics_listing = events.ical_feed
    cal = create_calendar(ics_listing)
    cal.publish
    render plain: cal.to_ical
  end
end
