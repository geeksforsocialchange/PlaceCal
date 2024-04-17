# frozen_string_literal: true

module Admin
  class PartnersController < Admin::ApplicationController
    include LoadUtilities
    before_action :set_partner, only: %i[show edit update destroy clear_address]
    before_action :set_tags, only: %i[new create edit]
    before_action :set_neighbourhoods, only: %i[new edit]
    before_action :set_partner_tags_controller, only: %i[create new edit update]

    def index
      @partners = policy_scope(Partner).order({ updated_at: :desc }, :name).includes(:address)

      respond_to do |format|
        format.html
        format.json do
          render json: PartnerDatatable.new(params,
                                            view_context: view_context,
                                            partners: @partners)
        end
      end
    end

    def new
      @partner = params[:partner] ? Partner.new(permitted_attributes(Partner)) : Partner.new
      @partner.tags = current_user.tags

      authorize @partner
    end

    def show
      authorize @partner
      redirect_to edit_admin_partner_path(@partner)
    end

    def create
      @partner = Partner.new(permitted_attributes(Partner))
      @partner.accessed_by_user = current_user

      authorize @partner

      # prevent someone trying to add the same service_area twice by mistake and causing a crash
      @partner.service_areas = @partner.service_areas.uniq(&:neighbourhood_id)

      respond_to do |format|
        if @partner.save
          format.html do
            flash[:success] = 'Partner was successfully created.'
            redirect_to edit_admin_partner_path(@partner)
          end

          format.json { render :show, status: :created, location: @partner }
        else
          format.html do
            flash.now[:danger] = 'Partner was not saved.'
            set_neighbourhoods
            render :new, status: :unprocessable_entity
          end
          format.json { render json: @partner.errors, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize @partner
      @sites = Site.sites_that_contain_partner(@partner)
    end

    def update
      authorize @partner

      mutated_params = permitted_attributes(@partner)

      @partner.accessed_by_user = current_user

      # prevent someone trying to add the same service_area twice by mistake and causing a crash
      uniq_service_areas = mutated_params[:service_areas_attributes]
                           .to_h
                           .map { |_, val| val }
                           .uniq { |service_area| service_area[:neighbourhood_id] }

      mutated_params[:service_areas_attributes] = uniq_service_areas

      hidden_in_this_edit = mutated_params[:hidden] == '1' && !@partner.hidden

      mutated_params[:hidden_blame_id] = current_user.id  if hidden_in_this_edit

      if @partner.update(mutated_params)
        # have to redirect on associated service area errors or form breaks
        if @partner.errors[:service_areas].any?
          flash[:danger] = @partner.errors[:service_areas][0]
        else
          flash[:success] = 'Partner was successfully updated.'
        end

        # important this needs to only fire on change to hidden
        if hidden_in_this_edit
          @partner.users.each do |user|
            ModerationMailer.hidden_message(
              user,
              @partner
            ).deliver
          end
          ModerationMailer.hidden_staff_alert(
            @partner
          ).deliver
        end

        redirect_to edit_admin_partner_path(@partner)
      else
        flash.now[:danger] = 'Partner was not saved.'
        set_neighbourhoods
        render :edit, status: :unprocessable_entity
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

    def clear_address
      authorize @partner

      if @partner.can_clear_address?(current_user)
        @partner.clear_address!
        render json: { message: 'Address cleared' }

      else
        render json: { message: 'Could not clear address' },
               status: :unprocessable_entity
      end
    end

    def lookup_name
      found = params[:name].present? && Partner.where('lower(name) = ?', params[:name].downcase).first

      render json: { name_available: found.nil? }
    end

    private

    def set_partner_tags_controller
      @partner_tags_controller =
        if current_user.root? || (@partner.present? && current_user.admin_for_partner?(@partner.id))
          'select2'
        else
          'partner-tags'
        end
    end

    def set_neighbourhoods
      if current_user.root? || (@partner.present? && current_user.admin_for_partner?(@partner.id))
        @all_neighbourhoods = Neighbourhood.order(:name)
      elsif @partner.present? && current_user.neighbourhood_admin_for_partner?(@partner.id)
        ids = @partner.owned_neighbourhood_ids | current_user.owned_neighbourhood_ids
        @all_neighbourhoods = Neighbourhood.where(id: ids)
      else
        ids = current_user.owned_neighbourhood_ids
        @all_neighbourhoods = Neighbourhood.where(id: ids)
      end
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
