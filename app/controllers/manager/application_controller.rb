module Manager
  class ApplicationController < ::ApplicationController
    include Pundit

    protect_from_forgery with: :exception

    before_action :authenticate_user!

    layout "manager"
  end
end
