# frozen_string_literal: true

class PartnersController < ApplicationController
  before_action :set_partner, only: :show
  before_action :set_day, only: :show

  # GET /partners
  # GET /partners.json
  def index
    # A subdomain indicates that a local site is being requested
    @site = Site.where(slug: request.subdomain).first

    if @site
      # Only get those partners relevant to the requested site.
      @partners = Partner.joins(:turfs).where(turfs: { id: @site.turfs }).distinct
    else # this is the canonical site.
      @partners = Partner.order(:name)
    end

    @map = generate_points(@partners) if @partners.detect(&:address)
  end

  # GET /partners/1
  # GET /partners/1.json
  def show
    # Period to show
    @period = params[:period] || 'week'
    @events = filter_events(@period, partner: @partner)
    # Map
    @map = generate_points(@events.map(&:place)) if @events.detect(&:place)
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

  private

  # This controller doesn't allow CRUD
  # def partner_params
  #   params.fetch(:partner, {})
  # end
end
