# frozen_string_literal: true

class PartnersController < ApplicationController
  include MapMarkers

  before_action :set_partner, only: %i[show embed]
  before_action :set_day, only: %i[show embed]
  before_action :set_primary_neighbourhood, only: [:index]
  before_action :set_site
  before_action :set_title, only: %i[index show]
  before_action :redirect_from_default_site

  PAGINATION_THRESHOLD = 20

  # GET /partners
  # GET /partners.json
  def index
    # Get all Partners that manage at least one other partner
    # @partners = Partner.managers.for_site(current_site).order(:name)

    # Get all partners based in the neighbourhoods associated with this site.
    @partners = Partner
                .for_site(current_site)
                .includes(:service_areas, :address)
                .order(:name)

    # show only partners with no service_areas
    @map = get_map_markers(@partners, true) if @partners.detect(&:address)
  end

  # # GET /places
  # # GET /places.json
  # def places_index
  #   @places = Partner.event_hosts.for_site(current_site).order(:name)
  #   @map = get_map_markers(@places) if @places.detect(&:address)
  # end

  # GET /partners/1
  # GET /partners/1.json
  def show
    upcoming_events = Event.by_partner(@partner).upcoming
    if upcoming_events.none?
      # If no events, show an appropriate message why
      @events = []
      @no_event_message = no_upcoming_events_reason(@partner)
    elsif upcoming_events.length < PAGINATION_THRESHOLD
      # If only a few, show them all with no pagination
      @events = sort_events(upcoming_events, 'time')
      @paginator = false
    else
      # If a lot, show a paginator by week
      @period = params[:period] || 'week'
      @events = filter_events(@period, partner_or_place: @partner)
      # Sort criteria
      @sort = params[:sort].to_s || 'time'
      @events = sort_events(@events, @sort)
      @paginator = true
    end

    @opening_times = @partner.human_readable_opening_times

    # Map
    @map = get_map_markers([@partner])

    respond_to do |format|
      format.html
      format.ics do
        cal = create_calendar(Event.by_partner(@partner).ical_feed, "#{@partner} - Powered by PlaceCal")
        cal.publish
        render plain: cal.to_ical
      end
    end
  end

  def embed
    period = params[:period] || 'week'
    limit = params[:limit] || '10'
    @events = filter_events(period, place: @partner, limit: limit)
    @events = sort_events(@events, 'time')
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
  # This controller doesn't allow CRUD
  # def partner_params
  #   params.fetch(:partner, {})
  # end
end
