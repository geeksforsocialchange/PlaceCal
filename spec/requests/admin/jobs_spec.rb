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

    def job_count(html, kind) = html.at_xpath("//dt[text()='#{I18n.t("admin.jobs.stats.#{kind}")}']/following-sibling::dd").text

    def finished_run(outcome, **attributes)
      create(:calendar).import_runs.create!(started_at: 5.minutes.ago).tap { it.finish!(outcome:, **attributes) }
    end

    it "lists import runs in the paginated table, with the outcome buttons and job counts inside it" do
      finished_run("bad_source", error: "404")
      finished_run("imported")
      html = page_html
      table = html.at_css("[data-controller='admin-table']")

      expect(table["data-admin-table-source-value"]).to eq(admin_import_runs_path(format: :json))
      expect(table.at_css("h1").text).to eq(I18n.t("admin.jobs.title"))
      expect(table.at_css("button[data-filter-value='failed'] span").text).to eq("1")
      expect(table.at_css("button[data-filter-value='imported'] span").text).to eq("1")
      expect(job_count(table, :waiting)).to eq("0")
    end

    it "refreshes itself: the table every few seconds, and the counts and failed jobs with it" do
      html = page_html

      expect(html.at_css("[data-controller='admin-table']")["data-admin-table-refresh-interval-value"]).to eq(Views::Admin::Jobs::Index::REFRESH_SECONDS.to_s)
      expect(html.at_css("[data-controller='live-counts']")["data-live-counts-url-value"]).to eq(admin_jobs_path(format: :json))
      expect(html.at_css("turbo-frame#failed_jobs_frame[data-live-counts-target='frame'][target='_top']")).to be_present
      expect(html.css("[data-live-count]").map { it["data-live-count"] }).to include("jobs.failed", "outcome.failed", "outcome.running")
    end

    it "gives the counts as JSON, keyed as the page marks them" do
      finished_run("error")
      finished_run("interrupted")
      create(:calendar).import_runs.create!(started_at: Time.current)

      get admin_jobs_url(host: admin_host, format: :json)

      expect(response.parsed_body).to include("jobs.waiting" => 0, "outcome.failed" => 2, "outcome.running" => 1, "outcome.imported" => 0)
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
      rows = html.css("#failed-jobs tbody tr").map { it.text.squish }

      expect(rows).to include(a_string_including(I18n.t("admin.jobs.kinds.import"), "Folk club feed", "Net::SMTPServerBusy: try later",
                                                 I18n.t("admin.jobs.actions.reimport")))
      expect(rows).to include(a_string_including(I18n.t("admin.jobs.kinds.email"), I18n.t("admin.jobs.actions.retry")))
      expect(html.css("#failed-jobs table").css("thead th").map { it.text.squish }).to eq(
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

      expect(job_count(page_html, :waiting)).to eq("1")
    end
  end
end
