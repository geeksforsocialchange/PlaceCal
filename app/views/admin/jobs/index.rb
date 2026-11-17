# frozen_string_literal: true

class Views::Admin::Jobs::Index < Views::Admin::Base
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::TimeAgoInWords

  JOB_KINDS = { 'CalendarImporterJob' => :import, 'MailDeliveryJob' => :email, 'ActionMailer::MailDeliveryJob' => :email,
                'RecurringMaintenanceJob' => :maintenance, 'RecurringCalendarScanJob' => :scan }.freeze
  STATE_BADGES = { idle: 'badge-success', in_queue: 'badge-info', in_worker: 'badge-info', error: 'badge-error', bad_source: 'badge-error' }.freeze

  prop :job_counts, Hash, reader: :private
  prop :calendar_counts, Hash, reader: :private
  prop :problem_calendars, ActiveRecord::Relation, reader: :private
  prop :busy_calendars, ActiveRecord::Relation, reader: :private
  prop :event_counts, Hash, reader: :private
  prop :failed_jobs, Array, reader: :private

  def view_template
    content_for(:title) { t('admin.jobs.title') }
    render_header
    render_stats
    render_calendars(:problem_calendars, problem_calendars, tone: 'error', &:critical_error)
    render_calendars(:busy_calendars, busy_calendars, tone: 'info') { |cal| cal.import_started_at && ago(cal.import_started_at) }
    render_failed_jobs if failed_jobs.any?
    render_empty_state if problem_calendars.none? && busy_calendars.none? && failed_jobs.none?
  end

  private

  def render_header
    div(class: 'mb-6') do
      h1(class: 'text-2xl font-bold') { t('admin.jobs.title') }
      p(class: 'text-sm text-gray-600 mt-1') { t('admin.jobs.description') }
    end
  end

  def render_stats
    div(class: 'flex flex-wrap gap-2 mb-8') do
      job_counts.each do |kind, count|
        badge(t("admin.jobs.stats.#{kind}"), count, kind == :failed && count.positive? ? 'badge-error' : 'badge-outline')
      end
      Calendar::ALLOWED_STATES.each do |state|
        badge(t("admin.jobs.states.#{state}"), calendar_counts[state.to_s] || 0, STATE_BADGES[state])
      end
    end
  end

  def badge(label, count, css)
    div(class: "badge badge-lg #{css} gap-1") do
      span { "#{label}:" }
      span(class: 'font-bold tabular-nums') { count.to_s }
    end
  end

  # The block gives the fourth column: the error for calendars with problems, when the import started for busy ones
  def render_calendars(section, calendars, tone:, &detail)
    return if calendars.none?

    div(class: 'mb-8') do
      h2(class: "font-bold flex items-center gap-2 mb-3 text-#{tone}") do
        plain t("admin.jobs.sections.#{section}")
        span(class: "badge badge-#{tone} badge-sm") { calendars.size.to_s }
      end
      div(class: 'overflow-x-auto') do
        table(class: 'table table-sm') do
          render_table_head(section)
          tbody { calendars.each { |cal| render_calendar_row(cal, tone, detail) } }
        end
      end
    end
  end

  def render_table_head(section)
    thead do
      tr do
        th { t('admin.table.calendar') }
        th { t('admin.table.partner') }
        th { t('admin.table.state') }
        th { t("admin.jobs.columns.#{section}") }
        th(class: 'text-right') { t('admin.table.events') }
      end
    end
  end

  def render_calendar_row(cal, tone, detail)
    tr(class: 'hover') do
      td { link_to cal.name, edit_admin_calendar_path(cal), class: 'link link-hover text-placecal-orange-dark font-medium' }
      td(class: 'text-sm') { link_to cal.organiser.name, admin_partner_path(cal.organiser), class: 'link link-hover' if cal.organiser }
      td { span(class: "badge badge-#{tone} badge-sm") { t("admin.jobs.states.#{cal.calendar_state}") } }
      td(class: "text-sm max-w-md truncate #{'text-error' if tone == 'error'}") { detail.call(cal) }
      td(class: 'text-right tabular-nums') { (event_counts[cal.id] || 0).to_s }
    end
  end

  def render_failed_jobs
    div(class: 'mb-8') do
      h2(class: 'font-bold flex items-center gap-2 mb-1 text-error') do
        plain t('admin.jobs.sections.failed_jobs')
        span(class: 'badge badge-error badge-sm') { job_counts[:failed].to_s }
      end
      p(class: 'text-sm text-gray-600 mb-3') { t('admin.jobs.failed_note', count: failed_jobs.size) }
      div(class: 'overflow-x-auto') do
        table(class: 'table table-sm') do
          thead { tr { %i[job about error failed_at actions].each { |column| th { t("admin.jobs.failed_columns.#{column}") } } } }
          tbody { failed_jobs.each { render_failed_row(it) } }
        end
      end
    end
  end

  def render_failed_row(failed)
    kind = JOB_KINDS[failed.job.class_name]
    calendar = Calendar.find_by(id: failed.job.arguments.dig('arguments', 0)) if kind == :import
    tr(class: 'hover') do
      td(class: 'text-sm font-medium') { kind ? t("admin.jobs.kinds.#{kind}") : failed.job.class_name }
      td(class: 'text-sm') { link_to calendar.name, edit_admin_calendar_path(calendar), class: 'link link-hover' if calendar }
      td(class: 'text-sm text-error max-w-md truncate', title: failed.message) { "#{failed.exception_class}: #{failed.message}" }
      td(class: 'text-sm whitespace-nowrap') { ago(failed.created_at) }
      td(class: 'whitespace-nowrap') { render_failed_actions(failed, calendar) }
    end
  end

  # A failed import is retried by re-importing its calendar, which also clears its error state
  def render_failed_actions(failed, calendar)
    div(class: 'flex gap-1') do
      if calendar
        button_to(t('admin.jobs.actions.reimport'), import_admin_calendar_path(calendar), class: 'btn btn-xs')
      else
        button_to(t('admin.jobs.actions.retry'), retry_admin_job_path(failed), class: 'btn btn-xs')
      end
      button_to(t('admin.jobs.actions.dismiss'), admin_job_path(failed), method: :delete, class: 'btn btn-xs btn-ghost')
    end
  end

  def ago(time)
    t('admin.time.ago', time: time_ago_in_words(time))
  end

  def render_empty_state
    div(class: 'text-center py-12') do
      icon(:check_circle, size: '12', css_class: 'mx-auto text-success/40 stroke-[1.5]')
      p(class: 'mt-3 font-medium text-success') { t('admin.jobs.empty.title') }
      p(class: 'text-sm text-gray-600') { t('admin.jobs.empty.description') }
    end
  end
end
