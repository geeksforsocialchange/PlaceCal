# frozen_string_literal: true

class Views::Admin::Jobs::Index < Views::Admin::Base
  prop :job_count, Integer, reader: :private
  prop :calendar_counts, Hash, reader: :private
  prop :error_calendars, ActiveRecord::Relation, reader: :private
  prop :busy_calendars, ActiveRecord::Relation, reader: :private

  def view_template
    render_header
    render_stats
    render_error_calendars if error_calendars.any?
    render_busy_calendars if busy_calendars.any?
    render_empty_state if error_calendars.none? && busy_calendars.none?
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
      div(class: 'badge badge-lg badge-outline gap-1') do
        span(class: 'text-gray-600') { "#{t('admin.jobs.stats.jobs')}:" }
        span(class: 'font-bold') { job_count.to_s }
      end
      Calendar::ALLOWED_STATES.each do |state_name|
        count = calendar_counts[state_name.to_s] || 0
        badge_class = state_badge_class(state_name)
        div(class: "badge badge-lg #{badge_class} gap-1") do
          span { "#{state_name.to_s.titleize}:" }
          span(class: 'font-bold') { count.to_s }
        end
      end
    end
  end

  def state_badge_class(state_name)
    case state_name
    when :idle then 'badge-success'
    when :in_queue, :in_worker then 'badge-info'
    when :error, :bad_source then 'badge-error'
    else 'badge-ghost'
    end
  end

  def render_error_calendars
    div(class: 'mb-6') do
      h2(class: 'font-bold flex items-center gap-2 mb-3 text-error') do
        icon(:warning, size: '4')
        plain t('admin.jobs.sections.error_calendars')
        span(class: 'badge badge-error badge-sm') { error_calendars.count.to_s }
      end

      div(class: 'overflow-x-auto') do
        table(class: 'table table-sm') do
          render_error_table_head
          tbody do
            error_calendars.order(:name).each { |cal| render_error_row(cal) }
          end
        end
      end
    end
  end

  def render_error_table_head
    thead do
      tr do
        th { t('admin.table.calendar') }
        th { t('admin.table.partner') }
        th { t('admin.table.state') }
        th { t('admin.table.error') }
        th(class: 'text-right') { t('admin.table.events') }
      end
    end
  end

  def render_error_row(cal)
    tr(class: 'hover') do
      td { link_to cal.name, edit_admin_calendar_path(cal), class: 'link link-hover text-placecal-orange font-medium' }
      td(class: 'text-sm') { link_to cal.partner.name, admin_partner_path(cal.partner), class: 'link link-hover' }
      td { span(class: 'badge badge-error badge-sm') { cal.calendar_state } }
      td(class: 'text-sm text-error max-w-md truncate') { cal.critical_error }
      td(class: 'text-right tabular-nums') { cal.events.count.to_s }
    end
  end

  def render_busy_calendars
    div(class: 'mb-6') do
      h2(class: 'font-bold flex items-center gap-2 mb-3 text-info') do
        span(class: 'loading loading-spinner loading-xs')
        plain t('admin.jobs.sections.busy_calendars')
        span(class: 'badge badge-info badge-sm') { busy_calendars.count.to_s }
      end

      div(class: 'overflow-x-auto') do
        table(class: 'table table-sm') do
          render_busy_table_head
          tbody do
            busy_calendars.order(:name).each { |cal| render_busy_row(cal) }
          end
        end
      end
    end
  end

  def render_busy_table_head
    thead do
      tr do
        th { t('admin.table.calendar') }
        th { t('admin.table.partner') }
        th { t('admin.table.state') }
        th { t('admin.table.strategy') }
        th(class: 'text-right') { t('admin.table.events') }
      end
    end
  end

  def render_busy_row(cal)
    tr(class: 'hover') do
      td { link_to cal.name, edit_admin_calendar_path(cal), class: 'link link-hover text-placecal-orange font-medium' }
      td(class: 'text-sm') { link_to cal.partner.name, admin_partner_path(cal.partner), class: 'link link-hover' }
      td { span(class: 'badge badge-info badge-sm') { cal.calendar_state } }
      td(class: 'text-sm') { cal.strategy }
      td(class: 'text-right tabular-nums') { cal.events.count.to_s }
    end
  end

  def render_empty_state
    div(class: 'text-center py-12') do
      icon(:check_circle, size: '12', css_class: 'mx-auto text-success/40 stroke-[1.5]')
      p(class: 'mt-3 font-medium text-success') { t('admin.jobs.empty.title') }
      p(class: 'text-sm text-gray-600') { t('admin.jobs.empty.description') }
    end
  end
end
