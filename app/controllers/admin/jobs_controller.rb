# frozen_string_literal: true

module Admin
  class JobsController < Admin::ApplicationController
    before_action :must_have_root_user

    def index
      @job_count = ActiveRecord::Base
        .connection.execute("select count(*) from delayed_jobs")
        .first["count"]

      @job_list = ActiveRecord::Base
        .connection.execute("select * from delayed_jobs limit 150")
    end

    private

    def must_have_root_user
      return if current_user.root?

      redirect_to root_path
    end
  end
end
