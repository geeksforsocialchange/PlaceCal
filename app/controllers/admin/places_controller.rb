module Admin
  class PlacesController < Admin::ApplicationController

    before_action :turfs, only: [:new, :create, :edit]

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
      if @place.save
        redirect_to admin_places_path
      else
        render 'new'
      end
    end

    def edit
      @place = Place.friendly.find(params[:id])
      authorize @place
    end

    def update
      @place = Place.friendly.find(params[:id])
      authorize @place
      if @place.update_attributes(place_params)
        redirect_to admin_places_path
      else
        render 'new'
      end
    end

    private
      def place_params
        params.require(:place).permit(:name, :short_description, :phone, :url, :address_id, :email, :status, :booking_info, :opening_times, :accessibility_info , address_attributes: [:id, :street_address, :street_address2, :city, :postcode, :_destroy ], :turf_ids => [])  
      end

  end
end
