# frozen_string_literal: true

class Views::Admin::Calendars::ImporterOverview < Views::Admin::Base
  include Phlex::Rails::Helpers::TimeAgoInWords
  include Phlex::Rails::Helpers::DistanceOfTimeInWords
  include Phlex::Rails::Helpers::DOMID

  POLL_INTERVAL = 3.seconds
  POLL_LIMIT = 10.minutes

  prop :calendar, Calendar, reader: :private

  def view_template
    return if calendar.new_record?

    div(data: {
          controller: 'import-status',
          action: 'turbo:frame-missing->import-status#missing turbo:fetch-request-error->import-status#retry',
          import_status_url_value: import_status_admin_calendar_path(calendar),
          import_status_interval_value: POLL_INTERVAL.in_milliseconds.to_i,
          import_status_limit_value: POLL_LIMIT.in_milliseconds.to_i
        }) do
      # Outside the frame so it exists before the final state arrives, or it would not be announced.
      p(role: 'status', class: 'sr-only', data: { import_status_target: 'announcer' })
      turbo_frame_tag(dom_id(calendar, :import_status), class: 'block', data: { import_status_target: 'frame' }) do
        div(data: { import_status_target: 'state', poll: calendar.busy?, announcement: }) do
          render_strip
        end
      end
    end
  end

  private

  def render_strip
    render_stale_warning
    retry_button = render_error_alert

    div(class: 'flex flex-wrap items-center gap-x-6 gap-y-2 p-4 bg-base-200/50 border border-base-300 rounded-lg') do
      retry_button = render_status_badge(retry_button)
      render_checksum_info
      render_last_import_info
      render_next_check_info
      render_latest_run_link
      render_retry_button(retry_button) if retry_button
    end

    render_notices
  end

  # Failures announce themselves through the error alert
  def announcement
    t('admin.calendars.importer.import_finished') if calendar.calendar_state.idle?
  end

  def render_stale_warning
    # Inside the polled frame its role=alert would be announced again on every reload
    return if calendar.busy?
    return unless calendar.checksum_updated_at.present? && calendar.last_import_at.present?
    return unless calendar.checksum_updated_at < 6.months.ago || calendar.last_import_at < 6.months.ago

    div(role: 'alert', class: 'alert alert-warning mb-4') do
      raw icon(:warning, size: '5', css_class: 'shrink-0 stroke-current')
      span { t('admin.calendars.warnings.stale') }
    end
  end

  def render_error_alert
    return unless calendar.calendar_state.error? || calendar.calendar_state.bad_source?

    div(role: 'alert', class: 'alert alert-error mb-4') do
      raw icon(:x_circle, size: '5', css_class: 'shrink-0 stroke-current')
      span { calendar.critical_error }
    end
    :error
  end

  def render_status_badge(retry_button)
    div(class: 'flex items-center gap-2') do
      span(class: 'text-sm font-medium text-gray-600') { t('admin.calendars.importer.status_label') }
      if calendar.calendar_state.idle?
        retry_button = :idle
        span(class: 'badge badge-success gap-1') do
          raw icon(:check, size: '3')
          plain t('admin.calendars.importer.success')
        end
      elsif calendar.calendar_state.in_queue? || calendar.calendar_state.in_worker?
        span(class: 'badge badge-info gap-1') do
          span(class: 'loading loading-spinner loading-xs')
          plain t('admin.calendars.importer.importing')
        end
      elsif calendar.calendar_state.error? || calendar.calendar_state.bad_source?
        span(class: 'badge badge-error gap-1') do
          raw icon(:x, size: '3')
          plain t('admin.table.error')
        end
      end
    end
    retry_button
  end

  def render_checksum_info
    return if calendar.checksum_updated_at.blank?

    div(class: 'flex items-center gap-2 text-sm') do
      span(class: 'text-gray-600') { t('admin.calendars.importer.source_changed') }
      span(class: 'font-medium') { t('admin.time.ago', time: time_ago_in_words(calendar.checksum_updated_at)) }
    end
  end

  def render_last_import_info
    return if calendar.last_import_at.blank?

    div(class: 'flex items-center gap-2 text-sm') do
      span(class: 'text-gray-600') { t('admin.calendars.importer.last_import') }
      span(class: 'font-medium') { t('admin.time.ago', time: time_ago_in_words(calendar.last_import_at)) }
    end
  end

  # From the scheduler's own record of the hourly scan, so it's absent where nothing schedules imports
  def render_next_check_info
    return if calendar.busy?

    next_check = SolidQueue::RecurringTask.find_by(key: 'calendar_scan')&.next_time
    return unless next_check

    div(class: 'flex items-center gap-2 text-sm') do
      span(class: 'text-gray-600') { t('admin.calendars.importer.next_check') }
      span(class: 'font-medium', title: I18n.l(next_check.in_time_zone, format: :long)) do
        t('admin.time.from_now', time: distance_of_time_in_words(Time.current, next_check))
      end
    end
  end

  def render_latest_run_link
    run = current_user.root? && calendar.import_runs.latest_first.first
    return unless run

    link_to t('admin.calendars.importer.latest_run', id: run.id), admin_import_run_path(run),
            class: 'text-sm link link-hover text-gray-600', data: { turbo_frame: '_top' }
  end

  def render_retry_button(retry_button)
    div(class: 'ml-auto') do
      simple_form_for(:import, url: import_admin_calendar_path(calendar), html: { data: { turbo_frame: '_top' } }) do |f|
        if retry_button == :idle
          raw f.submit(t('admin.calendars.importer.reimport'),
                       class: 'btn btn-sm bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange')
        elsif retry_button == :error
          raw f.submit(t('admin.calendars.importer.retry_import'),
                       class: 'btn btn-sm btn-error')
        end
      end
    end
  end

  def render_notices
    return if calendar.notices.blank?

    div(class: 'collapse collapse-arrow bg-warning/10 border border-warning/30 rounded-lg mt-4') do
      input(type: 'checkbox')
      div(class: 'collapse-title font-medium text-warning-content flex items-center gap-2 py-3 min-h-0') do
        raw icon(:warning, size: '4')
        plain t('admin.calendars.importer.notices')
        span(class: 'badge badge-warning badge-sm') { calendar.notices.count.to_s }
      end
      div(class: 'collapse-content') do
        ul(class: 'space-y-1') do
          calendar.notices.tally.each do |text, count|
            li(class: 'text-sm flex items-start gap-2') do
              span(class: 'text-warning') { "\u2022" }
              span do
                plain text
                if count > 1
                  whitespace
                  span(class: 'badge badge-ghost badge-xs') { "#{count}x" }
                end
              end
            end
          end
        end
      end
    end
  end
end
