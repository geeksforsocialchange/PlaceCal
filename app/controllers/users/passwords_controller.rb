# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  before_action :set_site
end
