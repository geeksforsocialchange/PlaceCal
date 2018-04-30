module Admin
  class UsersController < Admin::ApplicationController

    def profile
    end

    def index
      @users = User.all
    end

    def edit
      @user = User.find(params[:id])
      @turfs = Turf.all
      @roles = User.role.values
    end

    def assign_turf
      @user = User.find(params[:id])
      if @user.update_attributes(user_turf_params)
        redirect_to admin_users_path
      else
        render 'edit'
      end
    end

    def update
      if current_user.update_attributes(user_params)
        redirect_to admin_root_path
      else
        render 'profile'
      end
    end

    private
    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :password ) 
    end

    def user_turf_params
      params.require(:user).permit(:role, turf_ids: [] ) 
    end
  end
end