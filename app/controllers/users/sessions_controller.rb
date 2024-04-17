# frozen_string_literal: true

require_relative 'auth_common'

class Users::SessionsController < Devise::SessionsController
  include Users::AuthCommon

  before_action :set_site
end
