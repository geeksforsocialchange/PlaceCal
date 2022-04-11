# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  include AuthCommon
  before_action :set_site
end
