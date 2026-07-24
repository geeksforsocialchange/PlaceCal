# frozen_string_literal: true

# app/controllers/events_controller.rb
class EventsController < ApplicationController
  include MapMarkers
  include OffsiteRedirect
  include Pagy::Offset::Method

  before_action :set_event, only: %i[show]
  before_action :set_day, only: :index
  before_action :set_primary_neighbourhood, only: :index
  before_action :set_site

  # GET /events
  # GET /events.json
  def index
    if directory_request? && html_format? && params[:simple].blank?
      render_directory_index
    else
      render_local_index
    end
  end

  def ical; end

  # GET /events/1
  # GET /events/1.json
  def show
    redirect_offsite_to_permalink(EventsQuery.new(site: current_site), @event)
    return if performed?

    if @event.partner_at_location
      @map = get_map_markers([@event.partner_at_location])
    elsif @event.address
      @map = get_map_markers([@event.address])
    end
    @containing_sites = Site.sites_that_contain_partner(@event.organiser) if directory_request? && @event.organiser
    respond_to do |format|
      format.html do
        render Views::Sites::Events::Show.new(
          event: @event, site: @site, map: @map, containing_sites: @containing_sites
        )
      end
      format.ics do
        track_ical_download
        cal = create_calendar([@event])
        cal.publish
        render plain: cal.to_ical
      end
    end
  end

  private

  # Treats a wildcard Accept header (curl, crawlers) as HTML, matching how
  # respond_to would serve it. The directory has no Site row, so falling
  # through to the local index would render a site-less local view.
  def html_format?
    request.format.html? || request.format == Mime::ALL
  end

  def set_event
    @event = Event.find(params[:id])
  end

  # Auto-select period based on event density
  # - Few events total: show all (future)
  # - Moderate density: show week view
  # - High density: show day view
  def default_period
    return params[:period] if params[:period].present?

    future_count = @query.future_count
    return 'future' if future_count < 20

    week_count = @query.next_7_days_count
    week_count > 20 ? 'day' : 'week'
  end

  def render_directory_index
    @period = params[:period] || 'week'
    event_site = resolve_partnership_site || current_site
    query = EventsQuery.new(site: event_site, day: @current_day)

    flat_events = query.flat_call(period: @period)
    flat_events = flat_events.where('events.summary ILIKE ?', "%#{params[:q]}%") if params[:q].present?

    @pagy, paginated = pagy(flat_events, limit: 40)
    @events = paginated.group_by { |e| e.dtstart.to_date }

    partnerships = Site.where(is_published: true)
                       .order(:name)
                       .pluck(:slug, :name)
                       .map { |slug, name| { slug: slug, name: name } }

    render Views::Directory::Events::Index.new(
      events: @events,
      site: @site,
      period: @period,
      current_day: @current_day,
      total_count: EventsQuery.new(site: current_site, day: @current_day).count_for_period('future'),
      partnerships_list: partnerships,
      selected_partnership: params[:partnership],
      query: params[:q],
      pagy: @pagy
    )
  end

  def render_local_index
    @repeating = params[:repeating] || 'on'
    @sort = params[:sort] || 'time'
    @selected_neighbourhood = params[:neighbourhood] if params[:neighbourhood].present? && Integer(params[:neighbourhood], exception: false)
    @query = EventsQuery.new(site: current_site, day: @current_day)
    @period = params[:period] || default_period

    @events = @query.call(
      period: @period,
      repeating: @repeating,
      sort: @sort,
      neighbourhood_id: @selected_neighbourhood
    )
    @truncated = @query.truncated
    @next_date = @query.next_event_after(@current_day)
    @show_monthly = @query.show_monthly?
    respond_to do |format|
      format.html do
        if params[:simple].present?
          render Views::Sites::Events::IndexSimple.new(events: @events), layout: false
        else
          render Views::Sites::Events::Index.new(
            events: @events, period: @period, sort: @sort, repeating: @repeating,
            current_day: @current_day, site: @site,
            selected_neighbourhood: @selected_neighbourhood,
            next_date: @next_date, truncated: @truncated,
            show_monthly: @show_monthly
          )
        end
      end
      format.text { render Views::Sites::Events::IndexText.new(events: @events), layout: false }
      format.ics { render_ical }
    end
  end

  def resolve_partnership_site
    return if params[:partnership].blank?

    Site.find_by(slug: params[:partnership], is_published: true)
  end

  def render_ical
    track_ical_download
    query = EventsQuery.new(site: @site)
    cal = create_calendar(query.for_ical)
    cal.publish
    render plain: cal.to_ical
  end
end
