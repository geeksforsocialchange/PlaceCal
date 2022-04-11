class Users::InvitationsController < Devise::InvitationsController
  before_action :devise_check_on_root_site

  protected

  def after_accept_path_for(resource)
    admin_root_path
  end

end
