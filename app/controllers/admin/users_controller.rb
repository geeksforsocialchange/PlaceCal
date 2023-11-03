# frozen_string_literal: true

module Admin
  class UsersController < Admin::ApplicationController
    before_action :set_user, only: %i[edit update destroy]
    before_action :validate_neighbourhood_relation, only: %i[create]

    def profile
      authorize current_user, :profile?
    end

    def update_profile
      authorize current_user, :update_profile?

      if update_user_profile
        bypass_sign_in(current_user)
        flash[:success] = 'User profile has been updated'
        redirect_to admin_profile_path

      else
        flash.now[:danger] = 'User profile was not updated'
        render 'profile', status: :unprocessable_entity
      end
    end

    def index
      @users = policy_scope(User).order({ updated_at: :desc }, :last_name, :first_name)
      authorize current_user

      respond_to do |format|
        format.html
        format.json do
          render json: UserDatatable.new(
            params,
            view_context: view_context,
            users: @users.includes(:neighbourhoods, :tags, :partners)
          )
        end
      end
    end

    def new
      @partners = collect_partners

      @user = User.new
      authorize @user
    end

    def edit
      @partners = collect_partners

      authorize @user
    end

    def update
      authorize @user

      if @user.update(permitted_attributes(@user))
        flash[:success] = 'User has been saved'
        redirect_to admin_users_path

      else
        flash.now[:danger] = 'User was not saved'
        render 'edit', status: :unprocessable_entity
      end
    end

    def create
      @user = User.new(permitted_attributes(User))

      authorize @user

      @user.skip_password_validation = true

      if @user.valid?
        @user.invite!
        flash[:success] = 'User has been created! An invite has been sent'
        redirect_to admin_users_path
      else
        Rails.logger.debug @user.errors.full_messages
        flash.now[:danger] = 'User was not created'
        render 'new', status: :unprocessable_entity
      end
    end

    def destroy
      authorize @user
      @user.destroy
      respond_to do |format|
        format.html do
          flash[:success] = 'User has been deleted successfully'
          redirect_to admin_users_url
        end

        format.json { head :no_content }
      end
    end

    private

    def collect_partners
      return policy_scope(Partner).where(id: params[:partner_id])&.map(&:id) if params[:partner_id]

      @user&.partners&.map(&:id)
    end

    def profile_params
      params.require(:user).permit(:first_name,
                                   :last_name,
                                   :email,
                                   :password,
                                   :password_confirmation,
                                   :current_password,
                                   :phone,
                                   :avatar)
    end

    def update_user_profile
      if profile_params[:current_password].present? ||
         profile_params[:password].present? ||
         profile_params[:password_confirmation].present?

        current_user.update_with_password(profile_params)
      else
        current_user.update_without_password(profile_params)
      end
    end

    def validate_neighbourhood_relation
      # sorry this is a monstrosity, it's what robocop made me do it
      # we only allow the neighbourhood_admin to assign Partners from their own Neighbourhood so any ids here are proof of a relationship
      return if current_user.root?
      return unless current_user.neighbourhood_admin? && params[:user][:partner_ids].reject { |id| id == '' }.empty?

      # we're about to refresh the page so save the users input
      @user = User.new(permitted_attributes(User))
      flash.now[:danger] = 'User was not created: You must assign a Partner to the User or you will not be able to access it after creation'
      render 'new', status: :unprocessable_entity
    end
  end
end
