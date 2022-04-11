# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  before_action :devise_check_on_root_site
  before_action :set_site
end
