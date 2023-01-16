# frozen_string_literal: true

module Admin
  class JobsController < Admin::ApplicationController
    before_action :must_have_root_user

    def index
      @job_count = ActiveRecord::Base
                   .connection.execute('select count(*) from delayed_jobs')
                   .first['count']

      @calendar_counts = Calendar.group(:calendar_state).count

      @error_calendars = Calendar.where(calendar_state: 'error')
      @busy_calendars = Calendar.where(calendar_state: 'in_worker')
    end

    private

    def must_have_root_user
      return if current_user.root?

      redirect_to root_path
    end
  end
end
