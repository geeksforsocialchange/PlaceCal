class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
 
    def after_sign_in_path_for(resource)
      if resource && resource.role.admin?
        superadmin_root_path
      elsif resource && resource.role.secretary?
        admin_root_url(:subdomain => 'admin')
      else 
        new_session_path
      end
    end
end
