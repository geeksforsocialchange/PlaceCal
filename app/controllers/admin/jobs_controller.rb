# frozen_string_literal: true

module Admin
  class JobsController < Admin::ApplicationController
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped
    before_action { redirect_to admin_root_path unless current_user.root? }

    def index
      render Views::Admin::Jobs::Index.new(dashboard_path: admin_jobs_dashboard_path)
    end
  end
end
