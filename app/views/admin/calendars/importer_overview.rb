# frozen_string_literal: true

class Views::Admin::Calendars::ImporterOverview < Views::Admin::Base
  include Phlex::Rails::Helpers::TimeAgoInWords

  prop :calendar, Calendar, reader: :private

  def view_template
    return if calendar.new_record?

    render_stale_warning
    retry_button = render_error_alert

    div(class: 'flex flex-wrap items-center gap-x-6 gap-y-2 p-4 bg-base-200/50 border border-base-300 rounded-lg') do
      retry_button = render_status_badge(retry_button)
      render_checksum_info
      render_last_import_info
      render_retry_button(retry_button) if retry_button
    end

    render_notices
  end

  private

  def render_stale_warning
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

  def render_retry_button(retry_button)
    div(class: 'ml-auto') do
      simple_form_for(:import, url: import_admin_calendar_path(calendar)) do |f|
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
