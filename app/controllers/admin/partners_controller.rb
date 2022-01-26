# frozen_string_literal: true

module Admin
  class PartnersController < Admin::ApplicationController
    include LoadUtilities
    before_action :set_partner, only: %i[show edit update destroy]
    before_action :set_tags, only: %i[new create edit]
    before_action :set_neighbourhoods, only: %i[new edit]

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
          format.html { redirect_to admin_partners_path, notice: 'Partner was successfully created.' }
          format.json { render :show, status: :created, location: @partner }
        else
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

      @partner.accessed_by_id = current_user.id

      if @partner.update(permitted_attributes(@partner))
        redirect_to edit_admin_partner_path(@partner)
      else
        render :edit
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

    def set_neighbourhoods
      @all_neighbourhoods = policy_scope(Neighbourhood).order(:name)
    end

    def user_not_authorized
      flash[:alert] = 'Unable to access'
      redirect_to admin_partners_url
    end

    def partner_params
      attributes = [ :name, :image, :summary, :description,
                     :public_name, :public_email, :public_phone,
                     :partner_name, :partner_email, :partner_phone,
                     :address_id, :url, :facebook_link, :twitter_handle,
                     :opening_times,
                     calendars_attributes: %i[id name source strategy place_id partner_id _destroy],
                     address_attributes: %i[street_address street_address2 street_address3 city postcode],
                     tag_ids: [] ]

      attributes << :slug if current_user.root?

      params.require(:partner).permit(attributes)
    end

    def setup_params
      params.require(:partner).permit(:name, address_attributes: %i[street_address postcode])
    end
  end
end
