module Admin
  class UsersController < Admin::ApplicationController

    def profile
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

  end
end