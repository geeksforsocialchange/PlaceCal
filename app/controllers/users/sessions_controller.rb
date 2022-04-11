# frozen_string_literal: true

require_relative 'auth_common'

class Users::SessionsController < Devise::SessionsController
  include Users::AuthCommon

  before_action :set_site

  protected

  # when we have authenticated the user take them to the admin site
  # 
  # == Parameters
  #   resource_or_scope: ignored
  # 
  # == Returns
  #   URL of admin site with correct path and subdomain
  #   
  def after_sign_in_path_for(resource_or_scope)
    route_for(
      :root,
      subdomain: Site::ADMIN_SUBDOMAIN
    )
  end
end
