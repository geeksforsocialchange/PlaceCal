class Users::InvitationsController < Devise::InvitationsController

  protected

  def after_accept_path_for(resource)
    admin_root_path
  end

end
