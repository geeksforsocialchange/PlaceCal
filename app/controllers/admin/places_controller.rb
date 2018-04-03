module Admin
  class PlacesController < Admin::ApplicationController
    before_action :secretary_authenticate

    def index
      @places = Place.all.order(:name)
    end

    def new
      @place = Place.new 
    end

    def create
      @place = Place.new(place_params)
      if @place.save
        redirect_to admin_places_path
      else
        render 'new'
      end
    end

    def edit
      @place = Place.friendly.find(params[:id])
    end

    def update
      @place = Place.friendly.find(params[:id])
      if @place.update_attributes(place_params)
        redirect_to admin_places_path
      else
        render 'new'
      end
    end

    private
      def place_params  
        params.require(:place).permit(:name, :short_description, :phone, :url, :address_id, :email, :status, :booking_info, :opening_times, :accessibility_info , address_attributes: [:id, :street_address, :street_address2, :city, :postcode, :_destroy ])  
      end

  end
end