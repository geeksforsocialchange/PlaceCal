# frozen_string_literal: true

class PartnersController < ApplicationController
  before_action :set_partner, only: :show
  before_action :set_day, only: :show

  # GET /partners
  # GET /partners.json
  def index

    # Is request.subdomain for a configured Site?
    @site = Site.where(slug: request.subdomain).first
    if @site
        
      # Get the partners that belong to this site via the relevant turfs.
      # TO DO: What's the idiomatic ActiveRecord way to do this query?
      @partners = Partner.joins(
        "INNER JOIN partners_turfs ON partners_turfs.partner_id = partners.id
        INNER JOIN turfs ON turfs.id = partners_turfs.turf_id
        INNER JOIN sites_turfs ON sites_turfs.turf_id = turfs.id AND sites_turfs.site_id = #{@site.id}")

      # uniq in case same Partner appears in multiple Turfs
      @partners = @partners.uniq.sort_by do |partner|
        partner.name
      end
        
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
