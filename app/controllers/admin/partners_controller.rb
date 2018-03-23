module Admin
  class PartnersController < Admin::ApplicationController
    before_action :secretary_authenticate

    def index
      @partners = Partner.all.order(:name)
    end

    def new
      @partner = Partner.new
      # @map = generate_points([@event.place]) if @event.place
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
      @partner = Partner.friendly.find(params[:id])
    end

    def update
      @partner = Partner.friendly.find(params[:id])
      if @partner.update_attributes(partner_params)
        redirect_to admin_partners_path
      else
        render 'new'
      end
    end

    private
      def partner_params  
        params.require(:partner).permit(:name, :image, :short_description, :public_name, :public_email, :public_phone, :partner_name, :partner_email, :partner_phone, :calendar_phone, :calendar_name, :calendar_email, calendars_attributes: [:id, :name, :source, :type, :place_id, :_destroy], places_attributes: [:id, :name, :short_description, :booking_info, :opening_times, :_destroy, :accessibility_info , address_attributes: [:id, :street_address, :street_address2, :city, :postcode ]], :place_ids => [])  
      end
  end
end