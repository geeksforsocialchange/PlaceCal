# frozen_string_literal: true

module Admin
  class PartnersController < Admin::ApplicationController
    include LoadUtilities
    before_action :set_partner, only: %i[show edit update destroy]
    before_action :set_tags, only: %i[new create edit]
    before_action :set_neighbourhoods, only: %i[new edit]
    before_action :set_service_area_map_ids, only: %i[new edit]

    def index
      @partners = policy_scope(Partner).order(:name).includes(:address)

      respond_to do |format|
        format.html
        format.json {
          render json: PartnerDatatable.new(params,
                                            view_context: view_context,
                                            partners: @partners)
        }
      end
    end

    def new
      @partner = params[:partner] ? Partner.new(permitted_attributes(Partner)) : Partner.new
      authorize @partner
    end

    def show
      authorize @partner
      redirect_to edit_admin_partner_path(@partner)
    end

    def create
      @partner = Partner.new(permitted_attributes(Partner))
      @partner.accessed_by_id = current_user.id

      authorize @partner

      respond_to do |format|
        if @partner.save
          format.html do
            flash[:success] = 'Partner was successfully created.'
            redirect_to admin_partners_path
          end

          format.json { render :show, status: :created, location: @partner }
        else
          format.html do
            flash.now[:danger] = 'Partner was not saved.'
            set_neighbourhoods
            set_service_area_map_ids
            render :new 
          end
          format.json { render json: @partner.errors, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize @partner
    end

    def update
      authorize @partner

      @partner.accessed_by_id = current_user.id

      if @partner.update(permitted_attributes(@partner))
        flash[:success] = 'Partner was successfully updated.'
        redirect_to edit_admin_partner_path(@partner)

      else
        flash.now[:danger] = 'Partner was not saved.'
        set_neighbourhoods
        set_service_area_map_ids
        render :edit
      end
    end

    def destroy
      authorize @partner
      @partner.destroy
      respond_to do |format|
        format.html do
          flash[:success] = 'Partner was successfully destroyed.'
          redirect_to admin_partners_url
        end
        format.json { head :no_content }
      end
    end

    def setup
      @partner = Partner.new
      authorize @partner

      render and return unless request.post?

      @partner.attributes = setup_params
      @partner.accessed_by_id = current_user.id

      if @partner.valid?
        redirect_to new_admin_partner_url(partner: setup_params)
      else
        render 'setup'
      end
    end

    private

    def set_service_area_map_ids
      # maps neighbourhood ID to service_area ID
      if @partner
        @service_area_id_map = @partner.
          service_areas.select(:id, :neighbourhood_id).
          map { |sa| { sa.neighbourhood_id => sa.id } }.
          reduce({}, :merge)

      else
        @service_area_id_map = {}
      end
    end

    def set_neighbourhoods
      @all_neighbourhoods = policy_scope(Neighbourhood).order(:name)
    end

    def user_not_authorized
      flash[:alert] = 'Unable to access'
      redirect_to admin_partners_url
    end

    def setup_params
      params.require(:partner).permit(:name, address_attributes: %i[street_address postcode])
    end
  end
end
