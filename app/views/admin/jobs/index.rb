# frozen_string_literal: true

class Views::Admin::Jobs::Index < Views::Admin::Base
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::TimeAgoInWords

  JOB_KINDS = { 'CalendarImporterJob' => :import, 'MailDeliveryJob' => :email, 'ActionMailer::MailDeliveryJob' => :email,
                'RecurringMaintenanceJob' => :maintenance, 'RecurringCalendarScanJob' => :scan }.freeze

  prop :job_counts, Hash, reader: :private
  prop :calendar_counts, Hash, reader: :private
  prop :failed_jobs, Array, reader: :private

  def view_template
    render_calendars
    render_failed_jobs if failed_jobs.any?
  end

  private

  def render_calendars
    Datatable(
      title: t('admin.jobs.title'),
      model: :calendars,
      column_titles: [t('admin.table.calendar'), t('admin.table.state'), t('admin.jobs.columns.error'),
                      t('admin.jobs.columns.last_tried'), t('admin.jobs.columns.last_succeeded')],
      columns: %i[name state_badge details import_started_at last_import_at],
      column_config: { state_badge: { sortable: false, fit: true }, details: { sortable: false },
                       import_started_at: { fit: true }, last_import_at: { fit: true } },
      default_sort: { column: 'name', direction: 'asc' },
      filters: [{ type: :radio, column: 'state', label: t('admin.table.state'), default: 'problem', options: state_options }],
      data: Calendar.none,
      source: admin_calendars_path(format: :json)
    ) { render_job_counts }
  end

  def state_options
    problems = CalendarDatatable::STATE_GROUPS['problem'].sum { calendar_counts[it].to_i }
    [{ value: 'problem', label: t('admin.jobs.state_groups.problem'), count: problems }] +
      Calendar::ALLOWED_STATES.map { { value: it.to_s, label: t("admin.jobs.states.#{it}"), count: calendar_counts[it.to_s].to_i } }
  end

  def render_job_counts
    dl(class: 'flex gap-4 text-sm') do
      job_counts.each do |kind, count|
        div(class: 'flex gap-1') do
          dt(class: 'text-gray-600') { t("admin.jobs.stats.#{kind}") }
          dd(class: "font-semibold tabular-nums #{'text-error' if kind == :failed && count.positive?}") do
            kind == :failed && count.positive? ? a(href: '#failed-jobs', class: 'link') { count.to_s } : count.to_s
          end
        end
      end
    end
  end

  def render_failed_jobs
    div(id: 'failed-jobs', class: 'bg-white shadow-sm rounded-xl overflow-hidden border border-gray-200 mt-8') do
      div(class: 'px-6 py-5 border-b border-gray-200 bg-gradient-to-r from-gray-50 to-white') do
        h2(class: 'text-xl font-semibold text-gray-900') { t('admin.jobs.sections.failed_jobs') }
        p(class: 'mt-1 text-sm text-gray-600') { t('admin.jobs.failed_note', count: failed_jobs.size) }
      end
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
      td(class: 'text-sm whitespace-nowrap') { t('admin.time.ago', time: time_ago_in_words(failed.created_at)) }
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
end
