# frozen_string_literal: true

require_relative 'auth_common'

class Users::PasswordsController < Devise::PasswordsController
  include Users::AuthCommon

  before_action :set_site

  # POST /resource/password
  def create
    resource_class.send_reset_password_instructions(resource_params)

    redirect_to new_user_password_path, notice: 'An email has been sent to that email address'
  end
end
