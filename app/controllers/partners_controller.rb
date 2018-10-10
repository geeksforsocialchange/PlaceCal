# frozen_string_literal: true

class PartnersController < ApplicationController
  before_action :set_partner, only: :show
  before_action :set_day, only: :show
  before_action :set_primary_neighbourhood, only: [:index]
  before_action :set_site
  before_action :set_title, only: %i[index show]

  # GET /partners
  # GET /partners.json
  def index
    # Get all Partners that manage at least one other Partner.
    @partners = Partner
      .joins("JOIN organisation_relationships o_r on o_r.subject_id = partners.id")
      .where(o_r: {verb: :manages}).distinct.order(:name)
    @map = generate_points(@partners) if @partners.detect(&:address)
  end

  # GET /places
  # GET /places.json
  def places_index
    # Get all Partners that have hosted an event in the last month or will host
    # an event in the future
    # !!!!!!!!!!! TODO !!!!!!!!!!!
    # !!!!!!!!!!! TODO !!!!!!!!!!!
    # !!!!!!!!!!! TODO !!!!!!!!!!!
    # Change this to use events.place_id
    # events.partner_id is only for testing
    # !!!!!!!!!!! TODO !!!!!!!!!!!
    # !!!!!!!!!!! TODO !!!!!!!!!!!
    # !!!!!!!!!!! TODO !!!!!!!!!!!
    @places = Partner.joins("JOIN events ON events.partner_id = partners.id")
    .where("events.dtstart > ?", Date.today-30).distinct.order(:name)


    @map = [] # generate_points(@places) if @places.detect(&:address)
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
