module Admin
  class ApplicationController < ::ApplicationController
    layout 'admin/application'

    include Pundit

    before_action :authenticate_user!
    protect_from_forgery with: :exception

    protected

    def user_policy
      UserPolicy.new(current_user, nil)
    end

    def root_authenticate?
      return if user_policy.check_root_role? 
      redirect_to admin_root_path
    end
  end
end
