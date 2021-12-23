# frozen_string_literal: true

module Admin
  class UsersController < Admin::ApplicationController
    before_action :set_user, only: %i[edit update destroy]
    before_action :set_roles_and_tags, only: %i[new create edit assign_tag update destroy]

    def profile
      authorize current_user, :profile?
    end

    def update_profile
      authorize current_user, :update_profile?
      if update_user_profile
        bypass_sign_in(current_user)
        redirect_to admin_root_path
      else
        render 'profile'
      end
    end

    def index
      @users = policy_scope(User).order(:last_name, :first_name)
      authorize current_user

      respond_to do |format|
        format.html
        format.json { render json: UserDatatable.new(
                                     params, 
                                     view_context: view_context, 
                                     users: @users.includes(:neighbourhoods, :tags, :partners)
                                   ) 
                    }
      end
    end

    def new
      @user = User.new
      authorize @user
    end

    def edit
      authorize @user
    end

    def update
      authorize @user

      if @user.update(permitted_attributes(@user))
        redirect_to admin_users_path
      else
        render 'edit'
      end
    end

    def create
      @user = User.new(permitted_attributes(User))

      authorize @user

      @user.skip_password_validation = true

      if @user.valid?
        @user.invite!
        redirect_to admin_users_path
      else
        Rails.logger.debug @user.errors.full_messages
        render 'new'
      end
    end

    def destroy
      authorize @user
      @user.destroy
      respond_to do |format|
        format.html { redirect_to admin_users_url, notice: 'User was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    def set_roles_and_tags
      @tags = Tag.all
      @roles = User.role.values
    end

    def profile_params
      params.require(:user).permit(:first_name,
                                   :last_name,
                                   :email,
                                   :password,
                                   :password_confirmation,
                                   :current_password,
                                   :phone,
                                   :avatar,
                                   :facebook_app_id,
                                   :facebook_app_secret
                                  )
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

  end
end
