# frozen_string_literal: true

module Admin
  class JobsController < Admin::ApplicationController
    FAILED_JOBS_SHOWN = 20

    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped
    before_action { redirect_to admin_root_path unless current_user.root? }
    before_action :set_failed_job, only: %i[retry destroy]

    def index
      run_counts = ImportRun.finished.group(:outcome).count.merge('running' => ImportRun.unfinished.count)
      respond_to do |format|
        format.html do
          render Views::Admin::Jobs::Index.new(
            job_counts:, run_counts:,
            failed_jobs: SolidQueue::FailedExecution.includes(:job).order(created_at: :desc).limit(FAILED_JOBS_SHOWN).to_a
          )
        end
        format.json { render json: Views::Admin::Jobs::Index.live_counts(job_counts, run_counts) }
      end
    end

    def retry
      @failed_job.retry
      redirect_to admin_jobs_path, notice: t('admin.jobs.flash.retried')
    end

    def destroy
      @failed_job.discard
      redirect_to admin_jobs_path, notice: t('admin.jobs.flash.dismissed')
    end

    private

    def set_failed_job
      @failed_job = SolidQueue::FailedExecution.find(params[:id])
    end

    def job_counts
      { waiting: SolidQueue::ReadyExecution.count + SolidQueue::ScheduledExecution.count,
        running: SolidQueue::ClaimedExecution.count,
        failed: SolidQueue::FailedExecution.count }
    end
  end
end
