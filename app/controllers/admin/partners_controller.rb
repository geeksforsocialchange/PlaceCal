# frozen_string_literal: true

module Admin
  class PartnersController < Admin::ApplicationController
    include LoadUtilities
    before_action :set_partner, only: %i[show edit update destroy]
    before_action :set_turfs, only: %i[new create edit]

    def index
      @partners = policy_scope(Partner).order(:name)
    end

    def new
      @partner = Partner.new
      authorize @partner
    end

    def create
      @partner = Partner.new(partner_params)
      # authorize @partner
      respond_to do |format|
        if @partner.save
          format.html { redirect_to admin_partners_path, notice: 'Partner was successfully created.' }
          format.json { render :show, status: :created, location: @partner }
        else
          puts @partner.errors.inspect
          format.html { render :new }
          format.json { render json: @partner.errors, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize @partner
    end

    def update
      authorize @partner
      if @partner.update_attributes(partner_params)
        redirect_to admin_partners_path
      else
        render 'new'
      end
    end

    def destroy
      authorize @partner
      @partner.destroy
      respond_to do |format|
        format.html { redirect_to admin_partners_url, notice: 'Partner was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    def user_not_authorized
      flash[:alert] = 'Unable to access'
      redirect_to admin_partners_url
    end

    def partner_params
      params.require(:partner).permit(
        :name, :image, :short_description, :public_name, :public_email,
        :public_phone, :partner_name, :partner_email, :partner_phone,
        :calendar_phone, :calendar_name, :calendar_email, :is_a_place, :url,
        calendars_attributes: %i[id name source strategy place_id partner_id _destroy],
        places_attributes: [
          :id, :name, :short_description, :booking_info,
          :opening_times, :_destroy, :accessibility_info,
          address_attributes: %i[id street_address street_address2 city postcode]
        ],
        turf_ids: [],
        place_ids: []
      )
    end
  end
end
