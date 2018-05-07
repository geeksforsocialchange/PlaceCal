module Admin
  class UsersController < Admin::ApplicationController
    before_action :set_user, only: %i[edit assign_turf update destroy]

    def profile
    end

    def index
      @users = User.all
    end

    def edit
      @turfs = Turf.all
      @roles = User.role.values
    end

    def assign_turf
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

    def destroy
      @user.destroy
      respond_to do |format|
        format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
        format.json { head :no_content }
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
