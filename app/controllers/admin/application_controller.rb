module Admin
  class ApplicationController < ::ApplicationController
    layout "admin/application"

    include Pundit

    before_action :authenticate_user!
    protect_from_forgery with: :exception

    protected
      def secretary_authenticate
        authorize current_user, :secretary?
      end
  end
end
