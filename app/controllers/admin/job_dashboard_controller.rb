# frozen_string_literal: true

module Admin
  # Mission Control Jobs' controllers inherit from this, so only root users reach the job dashboard
  class JobDashboardController < ::ApplicationController
    before_action :authenticate_user!
    before_action { redirect_to main_app.admin_root_path unless current_user.root? }
  end
end
