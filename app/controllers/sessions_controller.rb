class Users::SessionsController < Devise::SessionsController

  protected  
    def after_sign_in_path_for(resource)
      if resource.role? && resource.role.admin?
        redirect_to superadmin_root_path
      else
        redirect_to admin_root_path
      end

    end 


end
