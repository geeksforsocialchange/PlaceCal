module Admin
  class ApplicationController < ::ApplicationController
    layout 'admin/application'

    include Pundit

    before_action :authenticate_user!
    protect_from_forgery with: :exception

    protected

    def secretary_authenticate
      return if current_user && current_user.role&.secretary?
      redirect_to admin_root_path
    end
  end
end
