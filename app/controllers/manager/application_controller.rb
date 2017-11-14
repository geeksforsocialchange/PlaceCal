module Manager
  class ApplicationController < ::ApplicationController

    before_action :authenticate_user!

    include Pundit

    protect_from_forgery with: :exception


  end
end
