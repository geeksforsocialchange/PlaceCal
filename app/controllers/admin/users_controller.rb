# frozen_string_literal: true

module Admin
  class UsersController < Admin::ApplicationController
    before_action :set_user, only: %i[edit assign_turf update destroy]
    before_action :set_roles_and_turfs, only: %i[new create edit assign_turf update destroy]

    def profile; end

    def index
      @users = User.all
      authorize current_user
    end

    def new
      @user = User.new
      authorize @user
    end

    def edit
      authorize @user
      @turfs = Turf.all
      @roles = User.role.values
    end

    def assign_turf
      authorize current_user, :assign_turf?
      if @user.update_attributes(user_turf_params)
        redirect_to admin_users_path
      else
        render 'edit'
      end
    end

    def create
      @user = User.new(user_turf_params)

      if @user.valid_for_invite
        @user.invite!
        redirect_to admin_users_path
      else
        Rails.logger.debug @user.errors.full_messages
        render 'new'
      end
    end

    def update
      if current_user.update_without_password(user_params)
        redirect_to admin_root_path
      else
        render 'profile'
      end
    end

    def destroy
      authorize current_user
      @user.destroy
      respond_to do |format|
        format.html { redirect_to admin_users_url, notice: 'User was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    def set_roles_and_turfs
      @turfs = Turf.all
      @roles = User.role.values
    end

    def user_params
      params.require(:user).permit(:first_name,
                                   :last_name,
                                   :email,
                                   :password,
                                   :phone)
    end

    def user_turf_params
      params.require(:user).permit(:first_name,
                                   :last_name,
                                   :email,
                                   :password,
                                   :phone,
                                   :role,
                                   turf_ids: [],
                                   partner_ids: [])
    end
  end
end
