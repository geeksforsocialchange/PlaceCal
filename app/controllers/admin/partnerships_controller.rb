# frozen_string_literal: true

module Admin
  class PartnershipsController < Admin::ApplicationController
    before_action :set_partnership, only: %i[edit update destroy]

    def index
      @partnerships = policy_scope(Partnership)
      authorize @partnerships, policy_class: PartnershipPolicy

      respond_to do |format|
        format.html do
          @partnerships = @partnerships.order(updated_at: :desc, name: :asc)
          render Views::Admin::Partnerships::Index.new(
            partnerships: @partnerships,
            admin_options: build_admin_options
          )
        end
        format.json do
          render json: PartnershipDatatable.new(
            params,
            view_context: view_context,
            partnerships: @partnerships
          )
        end
      end
    end

    def new
      @partnership = Partnership.new
      authorize @partnership
      render Views::Admin::Partnerships::New.new(partnership: @partnership)
    end

    def edit
      authorize @partnership
      @tag = @partnership
      @partners = @partnership.partners
      render Views::Admin::Partnerships::Edit.new(partnership: @partnership, current_user: current_user)
    end

    def create
      @partnership = Partnership.new(permitted_attributes(Partnership.new))
      authorize @partnership
      respond_to do |format|
        if @partnership.save
          format.html do
            flash[:success] = 'Partnership has been created'
            redirect_to admin_partnerships_path
          end
          format.json { render :show, status: :created, location: @partnership }
        else
          format.html do
            flash.now[:danger] = 'Partnership was not created'
            render Views::Admin::Partnerships::New.new(partnership: @partnership), status: :unprocessable_content
          end
          format.json { render json: @partnership.errors, status: :unprocessable_content }
        end
      end
    end

    def update
      authorize @partnership

      # Accept either :tag or :partnership params (form uses :tag for shared tag form)
      param_key = params.key?(:tag) ? :tag : :partnership
      attributes = params.require(param_key).permit(policy(@partnership).permitted_attributes)

      if current_user.partner_admin?
        attributes[:partner_ids] =
          helpers.all_partners_for(@partnership, attributes)
      end

      if @partnership.update(attributes)
        flash[:success] = 'Partnership was saved successfully'
        redirect_to admin_partnerships_path
      else
        @tag = @partnership
        flash.now[:danger] = 'Partnership was not saved'
        render Views::Admin::Partnerships::Edit.new(partnership: @partnership, current_user: current_user), status: :unprocessable_content
      end
    end

    def destroy
      authorize @partnership
      @partnership.destroy
      respond_to do |format|
        format.html do
          flash[:success] = 'Partnership was deleted'
          redirect_to admin_partnerships_url
        end
        format.json { head :no_content }
      end
    end

    private

    def build_admin_options
      admin_ids = TagsUser.where(tag_id: Partnership.select(:id)).distinct.pluck(:user_id)
      User.where(id: admin_ids).order(:first_name, :last_name).map do |u|
        name = [u.first_name, u.last_name].compact.join(' ')
        name = u.email.split('@').first if name.blank?
        { value: u.id.to_s, label: name }
      end
    end

    def set_partnership
      @partnership = Partnership.friendly.find(params[:id])
    end
  end
end
