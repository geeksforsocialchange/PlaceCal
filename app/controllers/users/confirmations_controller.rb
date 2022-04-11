# frozen_string_literal: true

require_relative 'auth_common'

class Users::ConfirmationsController < Devise::ConfirmationsController
  include Users::AuthCommon
end
