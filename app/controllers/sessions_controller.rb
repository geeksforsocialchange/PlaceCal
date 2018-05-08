class Users::SessionsController < Devise::SessionsController

  protected  
    def after_sign_in_path_for(resource)
      redirect_to admin_root_path
    end 

end
