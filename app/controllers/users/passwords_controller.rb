# frozen_string_literal: true

require_relative 'auth_common'

class Users::PasswordsController < Devise::PasswordsController
  include Users::AuthCommon

  before_action :set_site

  def new
    self.resource = resource_class.new
    render Views::Devise::Passwords::New.new
  end

  def edit
    self.resource = resource_class.new
    resource.reset_password_token = params[:reset_password_token]
    render Views::Devise::Passwords::Edit.new
  end

  # POST /resource/password
  def create
    resource_class.send_reset_password_instructions(resource_params)

    redirect_to new_user_password_path, notice: 'If a PlaceCal account is associated with the submitted email address, password reset instructions have been sent.'
  end
end
