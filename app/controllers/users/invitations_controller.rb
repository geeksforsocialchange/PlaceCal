class Users::InvitationsController < Devise::InvitationsController
  include AuthCommon

  protected

  def after_accept_path_for(resource)
    admin_root_path
  end

end
