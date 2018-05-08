class PartnersController < ApplicationController
  before_action :set_partner, only: :show
  before_action :set_day, only: :show

  # GET /partners
  # GET /partners.json
  def index
    @partners = Partner.order(:name)
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

  # GET /partners/new
  def new
    @partner = Partner.new
  end

  # GET /partners/1/edit
  def edit; end

  # POST /partners
  # POST /partners.json
  def create
    @partner = Partner.new(partner_params)

    respond_to do |format|
      if @partner.save
        format.html { redirect_to @partner, notice: 'Partner was successfully created.' }
        format.json { render :show, status: :created, location: @partner }
      else
        format.html { render :new }
        format.json { render json: @partner.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /partners/1
  # PATCH/PUT /partners/1.json
  def update
    default_update(@partner, partner_params)
  end

  # DELETE /partners/1
  # DELETE /partners/1.json
  def destroy
    @partner.destroy
    respond_to do |format|
      format.html { redirect_to partners_url, notice: 'Partner was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_partner
    @partner = Partner.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def partner_params
    params.fetch(:partner, {})
  end
end
