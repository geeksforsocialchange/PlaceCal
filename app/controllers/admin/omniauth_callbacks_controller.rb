# frozen_string_literal: true

module Admin
  class OmniauthCallbacksController < Admin::ApplicationController
    def setup
    end

    def failure
      redirect_to admin_calendars_path
    end

    private

    def omniauth_params
      request.env['omniauth.auth']['credentials']
    end

    def request_params
      request.env['omniauth.params']
    end
  end
end
