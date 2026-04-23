# frozen_string_literal: true

class PartnersController < ApplicationController
  include MapMarkers

  before_action :set_partner, only: %i[show embed]
  before_action :set_day, only: %i[show embed]
  before_action :set_primary_neighbourhood, only: [:index]
  before_action :set_site
  before_action :set_title, only: %i[index show]
  before_action :redirect_from_default_site

  PAGINATION_THRESHOLD = 30

  # GET /partners
  # GET /partners.json
  def index
    @selected_category = params[:category] if params[:category].present? && Integer(params[:category], exception: false)
    @selected_neighbourhood = params[:neighbourhood] if params[:neighbourhood].present? && Integer(params[:neighbourhood], exception: false)
    @page = (params[:page] || 1).to_i

    query = PartnersQuery.new(site: current_site)
    @partners = query.call(
      neighbourhood_id: @selected_neighbourhood,
      tag_id: @selected_category,
      page: @page
    )

    @map = get_map_markers(@partners) if @partners.detect(&:address)
    @filter_params = { category: @selected_category, neighbourhood: @selected_neighbourhood }.compact

    render Views::Partners::Index.new(
      partners: @partners, site: @site,
      map: @map, selected_category: @selected_category,
      selected_neighbourhood: @selected_neighbourhood,
      page: @page,
      total_pages: query.total_pages,
      page_letter_ranges: query.page_letter_ranges,
      filter_params: @filter_params
    )
  end

  # GET /partners/1
  # GET /partners/1.json
  def show
    redirect_to root_path if @partner.hidden

    upcoming_count = Event.by_organiser_or_place(@partner).upcoming.count
    if upcoming_count.zero?
      # If no events, show an appropriate message why
      @events = []
      @no_event_message = no_upcoming_events_reason(@partner)
    elsif upcoming_count < PAGINATION_THRESHOLD
      # If only a few, show them all with no pagination
      query = EventsQuery.new(site: nil, day: @current_day)
      @events = query.call(period: 'future', organiser_or_place: @partner, sort: 'time')
      @paginator = false
    else
      # If a lot, paginate - default to "upcoming" which shows next N events
      partner_events = Event.by_organiser(@partner)
      weekly_count = partner_events.find_next_7_days(@current_day).count
      @date_period = weekly_count >= EventsQuery::WEEKLY_DENSITY_THRESHOLD ? 'week' : 'month'
      @period = params[:period] || 'upcoming'
      @sort = params[:sort] || 'time'
      @repeating = params[:repeating] || 'on'
      query = EventsQuery.new(site: nil, day: @current_day)
      @events = query.call(
        period: @period,
        organiser_or_place: @partner,
        repeating: @repeating,
        sort: @sort
      )
      @show_monthly = query.show_monthly?
      @paginator = true
    end

    # Map
    @map = get_map_markers([@partner])

    respond_to do |format|
      format.html do
        render Views::Partners::Show.new(
          partner: @partner, site: @site, current_day: @current_day,
          map: @map, events: @events,
          period: @period, date_period: @date_period, sort: @sort,
          repeating: @repeating, no_event_message: @no_event_message,
          paginator: @paginator, show_monthly: @show_monthly || false
        )
      end
      format.ics do
        track_ical_download
        cal = create_calendar(Event.by_organiser_or_place(@partner).ical_feed, "#{@partner} - Powered by PlaceCal")
        cal.publish
        render plain: cal.to_ical
      end
    end
  end

  def embed
    period = params[:period] || 'week'
    limit = params[:limit]&.to_i || 10
    query = EventsQuery.new(site: nil, day: @current_day)
    @events = query.call(period: period, place: @partner, sort: 'time', limit: limit)
    response.headers.except! 'X-Frame-Options'
    render layout: false
  end

  private

  def no_upcoming_events_reason(partner)
    if partner.calendars.none?
      'This partner does not list events on PlaceCal.'
    else
      'This partner has no upcoming events.'
    end
  end

  def set_title
    @title =
      if current_site&.primary_neighbourhood
        "Partners #{current_site.join_word} #{current_site.primary_neighbourhood.name}"
      else
        'All Partners'
      end
  end
end
