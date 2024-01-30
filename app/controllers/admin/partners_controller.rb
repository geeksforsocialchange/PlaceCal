# frozen_string_literal: true

module Admin
  class PartnersController < Admin::ApplicationController
    include LoadUtilities
    before_action :set_partner, only: %i[show edit update destroy]
    before_action :set_tags, only: %i[new create edit]
    before_action :set_neighbourhoods, only: %i[new edit]
    before_action :set_partner_tags_controller, only: %i[new edit update]

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
            redirect_to admin_partners_path
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
      # @sites = Site.sites_that_contain_partner(@partner)
      return unless @partner.hidden

      @mod_email = User.find(@partner.hidden_blame_id).email
    end

    def update
      authorize @partner

      mutated_params = permitted_attributes(@partner)

      before = @partner.hidden

      @partner.accessed_by_user = current_user

      # prevent someone trying to add the same service_area twice by mistake and causing a crash
      uniq_service_areas = mutated_params[:service_areas_attributes]
                           .to_h
                           .map { |_, val| val }
                           .uniq { |service_area| service_area[:neighbourhood_id] }

      mutated_params[:service_areas_attributes] = uniq_service_areas

      hidden_in_this_edit = mutated_params[:hidden] == '1' && !@partner.hidden

      mutated_params[:hidden_blame_id] = current_user.id  if hidden_in_this_edit
      Rails.logger.debug '0' * 80
      Rails.logger.debug mutated_params
      Rails.logger.debug '0' * 80

      if @partner.update(mutated_params)
        # have to redirect on associated service area errors or form breaks
        if @partner.errors[:service_areas].any?
          flash[:danger] = @partner.errors[:service_areas][0]
        else
          flash[:success] = 'Partner was successfully updated.'
        end

        # important this needs to only fire on change to hidden
        puts '?' * 80
        @partner.users.each { |u| puts u.full_name }
        puts '?' * 80

        if hidden_in_this_edit
          ModerationMailer.hidden_message(
            @partner.users,
            @partner.name,
            @partner.hidden_reason_html,
            User.find(@partner.hidden_blame_id).email
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

    def setup
      @partner = Partner.new
      authorize @partner

      render and return unless request.post?

      @partner.attributes = setup_params
      @partner.accessed_by_user = current_user

      if @partner.valid?
        redirect_to new_admin_partner_url(partner: setup_params)
      else
        render 'setup', status: :unprocessable_entity
      end
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
