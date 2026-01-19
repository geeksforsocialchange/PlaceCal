# frozen_string_literal: true

module Admin
  class PartnersController < Admin::ApplicationController
    include LoadUtilities

    before_action :set_partner, only: %i[show edit update destroy clear_address]
    before_action :set_tags, only: %i[new create edit]
    before_action :set_neighbourhoods, only: %i[new edit]
    before_action :set_partner_tags_controller, only: %i[create new edit update]

    def index
      @partners = policy_scope(Partner).includes(:address)

      respond_to do |format|
        format.html { @partners = @partners.order(updated_at: :desc, name: :asc) }
        format.json do
          render json: PartnerDatatable.new(params,
                                            view_context: view_context,
                                            partners: @partners)
        end
      end
    end

    def new
      @partner = params[:partner] ? Partner.new(permitted_attributes(Partner)) : Partner.new
      @partner.partnerships = current_user.partnerships

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
          invitation_result = invite_partner_admin(@partner) if invited_admin_params[:email].present?

          format.html do
            flash[:success] = build_success_flash(invitation_result)
            redirect_to after_create_redirect_path(@partner)
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
      return render json: { name_available: true, similar: [] } if params[:name].blank?

      name = params[:name].downcase
      exact_match = Partner.where('lower(name) = ?', name).first

      # Find similar partners (fuzzy match) - limit to 5 for performance
      similar = Partner.where('lower(name) LIKE ?', "%#{name}%")
                       .or(Partner.where('lower(name) LIKE ?', "%#{name.split.first}%"))
                       .where.not(id: exact_match&.id)
                       .limit(5)
                       .pluck(:id, :name)
                       .map { |id, n| { id: id, name: n } }

      render json: {
        name_available: exact_match.nil?,
        exact_match: exact_match&.slice(:id, :name),
        similar: similar
      }
    end

    private

    def after_create_redirect_path(partner)
      case params[:after_create]
      when 'add_calendar'
        new_admin_calendar_path(partner_id: partner.id)
      else
        edit_admin_partner_path(partner)
      end
    end

    def invited_admin_params
      params.dig(:partner, :invited_admin) || {}
    end

    def invite_partner_admin(partner)
      admin_params = invited_admin_params
      email = admin_params[:email]&.strip&.downcase
      return { status: :skipped } if email.blank?

      user = User.find_by(email: email)

      if user
        # Existing user - just add as partner admin
        user.partners << partner unless user.partners.include?(partner)
        { status: :existing_user, email: email }
      else
        # New user - create and invite
        user = User.new(
          email: email,
          first_name: admin_params[:first_name],
          last_name: admin_params[:last_name],
          phone: admin_params[:phone],
          role: 'citizen'
        )
        user.skip_password_validation = true
        user.partners << partner

        if user.valid?
          # In development, skip sending email so Letter Opener doesn't interrupt the flow
          # Instead, we'll show the invitation link in the flash message
          user.skip_invitation = Rails.env.development?
          user.invite!
          invitation_url = accept_user_invitation_url(invitation_token: user.raw_invitation_token)
          { status: :invited, email: email, invitation_url: invitation_url }
        else
          Rails.logger.warn "Failed to invite partner admin: #{user.errors.full_messages.join(', ')}"
          { status: :failed, email: email, errors: user.errors.full_messages }
        end
      end
    end

    def build_success_flash(invitation_result)
      message = 'Partner was successfully created.'
      return message unless invitation_result

      message + case invitation_result[:status]
                when :invited then invitation_flash(invitation_result)
                when :existing_user then " #{invitation_result[:email]} has been added as an admin."
                when :failed then " However, the admin invitation failed: #{invitation_result[:errors].join(', ')}"
                else ''
                end
    end

    def invitation_flash(result)
      msg = " Invitation sent to #{result[:email]}."
      msg += " <a href=\"#{result[:invitation_url]}\" target=\"_blank\" class=\"underline\">View invitation</a>" if Rails.env.development? && result[:invitation_url]
      msg
    end

    def set_partner_tags_controller
      @partner_tags_controller =
        if current_user.root? || (@partner.present? && current_user.admin_for_partner?(@partner.id))
          'tom-select'
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
