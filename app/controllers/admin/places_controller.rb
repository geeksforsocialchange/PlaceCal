module Admin
  class PlacesController < Admin::ApplicationController
    include LoadUtilities
    before_action :set_place, only: %i[show edit update destroy]
    before_action :set_turfs, only: %i[new create edit]

    def index
      @places = policy_scope(Place)
    end

    def new
      @place = Place.new
      authorize @place
    end

    def create
      @place = Place.new(place_params)
      authorize @place
      respond_to do |format|
        if @place.save
          format.html { redirect_to admin_places_path, notice: 'Place was successfully created.' }
          format.json { render :show, status: :created, location: @place }
        else
          format.html { render :new }
          format.json { render json: @place.errors, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize @place
    end

    def update
      authorize @place
      if @place.update_attributes(place_params)
        redirect_to admin_places_path
      else
        render 'new'
      end
    end

    def destroy
      @place.destroy
      respond_to do |format|
        format.html { redirect_to admin_places_url, notice: 'Place was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    def place_params
      params.require(:place).permit(:name, :short_description, :phone, :url, :address_id, :email, :status, :booking_info, :opening_times, :accessibility_info , address_attributes: [:id, :street_address, :street_address2, :city, :postcode, :_destroy ], :turf_ids => [])
    end

  end
end
