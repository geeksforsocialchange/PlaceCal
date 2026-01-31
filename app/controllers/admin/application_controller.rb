# frozen_string_literal: true

module Admin
  class ApplicationController < ::ApplicationController
    layout 'admin/application'

    before_action :authenticate_user!
    before_action :set_appsignal_namespace
    protect_from_forgery with: :exception

    private

    def set_appsignal_namespace
      Appsignal::Transaction.current.set_namespace('admin')
    end
  end
end
