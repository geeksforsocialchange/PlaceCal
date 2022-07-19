# frozen_string_literal: true

module Admin
  class OmniauthCallbacksController < Admin::ApplicationController
    # NOTE: this is currently not used (July '22) as it was a part of the
    #   facebook integration. it is left here as it may become desirable
    #   to have omniauth in the future and the code is already here

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
