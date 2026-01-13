# frozen_string_literal: true

module Admin
  class DebugController < Admin::ApplicationController
    before_action :require_root_user

    def icons
      @icons = SvgIconsHelper::ICONS
    end

    private

    def require_root_user
      return if current_user&.root?

      flash[:error] = 'You need to be a root admin to access this page.'
      redirect_to admin_root_path
    end
  end
end
