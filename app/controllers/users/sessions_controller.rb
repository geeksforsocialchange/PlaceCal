# frozen_string_literal: true

require_relative 'auth_common'

class Users::SessionsController < Devise::SessionsController
  include Users::AuthCommon

  before_action :set_site

  def new
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    render Views::Devise::Sessions::New.new
  end
end
