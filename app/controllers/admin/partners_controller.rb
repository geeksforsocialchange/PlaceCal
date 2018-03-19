module Admin
  class PartnersController < Admin::ApplicationController

    def index
      @partners = Partner.all.order(:name)
    end

    def new
      @partner = Partner.new
      @partner.places.build
      @partner.places.first.build_address 
    end

    def create
      @partner = Partner.new(partner_params)
      if @partner.save
        redirect_to admin_partners_path
      else
        render 'new'
      end
    end

    def edit
      @partner = Partner.find(params[:id])
    end

    def update
    end

    private

      def partner_params  
        params.require(:partner).permit(:name, :image, :short_description, :public_name, :public_email, :public_phone, :partner_name, :partner_email, :partner_phone, :calendar_phone, :calendar_name, :calendar_email, calendars_attributes: [:id, :name, :source, :type, :place_id], places_attributes: [:id, :name, :short_description, :booking_info, :opening_times, :accessibility_info , address_attributes: [:id, :street_address, :street_address2, :city, :postcode ]], :place_ids => [])  
      end

  end
end