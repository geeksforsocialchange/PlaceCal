# frozen_string_literal: true

require_relative 'auth_common'

class Users::PasswordsController < Devise::PasswordsController
  include Users::AuthCommon

  before_action :set_site
end
