# frozen_string_literal: true

require_relative 'auth_common'

class Users::InvitationsController < Devise::InvitationsController
  include Users::AuthCommon

  before_action :set_site
end
