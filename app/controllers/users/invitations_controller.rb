# frozen_string_literal: true

require_relative 'auth_common'

class Users::InvitationsController < Devise::InvitationsController
  include Users::AuthCommon

  before_action :set_site

  protected

  def after_accept_path_for(resource)
    admin_root_path
  end

end
