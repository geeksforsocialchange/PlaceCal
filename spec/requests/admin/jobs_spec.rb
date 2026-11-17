# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin background jobs", type: :request do
  it "sends a signed-out visitor to sign in" do
    get admin_jobs_url(host: admin_host)
    expect(response).to redirect_to(new_user_session_path)
  end

  it "turns away a user who isn't root" do
    sign_in create(:citizen_user)
    get admin_jobs_url(host: admin_host)
    expect(response).to redirect_to(admin_root_path)
  end

  context "as a root user" do
    before { sign_in create(:root_user) }

    def page_html
      get admin_jobs_url(host: admin_host)
      Nokogiri::HTML(response.body)
    end

    it "says all is clear when no calendar needs attention" do
      expect(page_html.text).to include(I18n.t("admin.jobs.empty.title"))
    end

    it "lists calendars with problems, with their error, and calendars queued or importing" do
      broken = create(:calendar, name: "Broken feed")
      broken.update_columns(calendar_state: "error", critical_error: "Calendar URL returned un-parsable data") # rubocop:disable Rails/SkipsModelValidations
      unreachable = create(:calendar, name: "Gone away")
      unreachable.update_columns(calendar_state: "bad_source", critical_error: "404") # rubocop:disable Rails/SkipsModelValidations
      busy = create(:calendar, name: "Busy feed")
      busy.update_columns(calendar_state: "in_worker", import_started_at: 2.minutes.ago) # rubocop:disable Rails/SkipsModelValidations

      text = page_html.text

      expect(text).to include("Broken feed", "Calendar URL returned un-parsable data", "Gone away", "Busy feed")
      expect(text).to include(I18n.t("admin.jobs.sections.problem_calendars"), I18n.t("admin.jobs.sections.busy_calendars"))
      expect(text).not_to include(I18n.t("admin.jobs.empty.title"))
    end

    def failed_job(class_name, arguments)
      job = SolidQueue::Job.create!(queue_name: "default", class_name:, arguments: { "arguments" => arguments })
      job.ready_execution&.destroy
      SolidQueue::FailedExecution.create!(job:, error: { exception_class: "Net::SMTPServerBusy", message: "try later", backtrace: ["x.rb:1"] })
    end

    it "lists failed jobs by what they were, with the error but no backtrace, and what to do about them" do
      calendar = create(:calendar, name: "Folk club feed")
      failed_job("CalendarImporterJob", [calendar.id, "2026-11-17", false])
      email = failed_job("MailDeliveryJob", %w[JoinMailer join_us deliver_now])

      html = page_html
      rows = html.css("table").last.css("tbody tr").map { it.text.squish }

      expect(rows).to include(a_string_including(I18n.t("admin.jobs.kinds.import"), "Folk club feed", "Net::SMTPServerBusy: try later",
                                                 I18n.t("admin.jobs.actions.reimport")))
      expect(rows).to include(a_string_including(I18n.t("admin.jobs.kinds.email"), I18n.t("admin.jobs.actions.retry")))
      expect(html.css("table").last.css("thead th").map { it.text.squish }).to eq(
        %w[job about error failed_at actions].map { I18n.t("admin.jobs.failed_columns.#{it}") }
      )
      expect(html.text).not_to include("x.rb:1")
      expect(html.at_css("form[action='#{retry_admin_job_path(email)}']")).to be_present
    end

    it "retries a failed job" do
      failed = failed_job("MailDeliveryJob", [])

      post retry_admin_job_url(failed, host: admin_host)

      expect(response).to redirect_to(admin_jobs_path)
      expect(SolidQueue::FailedExecution.exists?(failed.id)).to be(false)
      expect(SolidQueue::ReadyExecution.where(job_id: failed.job_id)).to exist
    end

    it "dismisses a failed job" do
      failed = failed_job("RecurringMaintenanceJob", [])

      delete admin_job_url(failed, host: admin_host)

      expect(response).to redirect_to(admin_jobs_path)
      expect(SolidQueue::Job.exists?(failed.job_id)).to be(false)
    end

    it "counts Solid Queue's waiting and running jobs" do
      SolidQueue::Job.create!(queue_name: "default", class_name: "CalendarImporterJob", arguments: {})

      expect(page_html.text).to include("#{I18n.t('admin.jobs.stats.waiting')}:1")
    end
  end
end
