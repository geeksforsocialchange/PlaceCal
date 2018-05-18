# frozen_string_literal: true

module Manager
  class ApplicationController < ::ApplicationController
    include Pundit

    before_action :authenticate_user!

    protect_from_forgery with: :exception
  end
end
