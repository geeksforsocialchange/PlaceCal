# frozen_string_literal: true

module Admin
  class ApplicationController < ::ApplicationController
    layout "admin/application"

    before_action :authenticate_user!
    protect_from_forgery with: :exception
  end
end
