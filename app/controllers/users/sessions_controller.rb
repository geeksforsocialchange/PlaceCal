# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :devise_check_on_root_site
  before_action :set_site

  protected

  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || admin_root_path
  end
end
