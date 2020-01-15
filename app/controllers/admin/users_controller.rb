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
      if current_user.update(profile_params)
        redirect_to admin_root_path
      else
        render 'profile'
      end
    end

    def index
      @users = User.all.order(:last_name, :first_name)
      authorize current_user
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

  end
end
