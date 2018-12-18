# frozen_string_literal: true

class PartnersController < ApplicationController
  before_action :set_partner, only: [:show, :embed]
  before_action :set_day, only: [:show, :embed]
  before_action :set_primary_neighbourhood, only: [:index]
  before_action :set_site
  before_action :set_title, only: %i[index show]

  # GET /partners
  # GET /partners.json
  def index
    # Get all Partners that manage at least one other partner
    # @partners = Partner.managers.for_site(current_site).order(:name)

    # Get all partners based in the neighbourhoods associated with this site.
    @partners = Partner.for_site(current_site).order(:name)

    @map = get_map_markers(@partners) if @partners.detect(&:address)
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
    # Period to show
    @period = params[:period] || 'week'
    @events = filter_events(@period, partner_or_place: @partner)
    @opening_times = @partner.human_readable_opening_times

    # Map
    if @events&.length.positive?
      @map = get_map_markers_from_events(@events)
    else
      @map = get_map_markers([@partner])
    end

    # Sort criteria
    @sort = params[:sort].to_s || 'time'
    @events = sort_events(@events, @sort)

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
