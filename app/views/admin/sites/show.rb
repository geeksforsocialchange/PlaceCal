# frozen_string_literal: true

class Views::Admin::Sites::Show < Views::Admin::Base
  prop :site, Site, reader: :private
  prop :calendars, ActiveRecord::Relation, reader: :private

  def view_template
    render_header
    render_stats
    render_calendars_table
  end

  private

  def render_header # rubocop:disable Metrics/AbcSize
    div(class: 'mb-6') do
      div(class: 'flex flex-wrap items-center justify-between gap-4') do
        div do
          h1(class: 'text-2xl font-bold') { site.name }
          p(class: 'text-sm text-gray-600 mt-1') { t('admin.sites.show.title') }
        end
        div(class: 'flex items-center gap-2') do
          link_to(edit_admin_site_path(site),
                  class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange') do
            icon(:edit, size: '4')
            plain t('admin.sites.show.edit_site')
          end
        end
      end
    end
  end

  def render_stats # rubocop:disable Metrics/AbcSize
    error_count = calendars.where(calendar_state: %i[error bad_source]).count
    div(class: 'grid grid-cols-1 md:grid-cols-3 gap-4 mb-6') do
      InfoCard(
        icon: :calendar, label: Calendar.model_name.human(count: 2),
        value: calendars.count.to_s, color: :orange
      )
      InfoCard(
        icon: :check, label: t('admin.labels.healthy'),
        value: calendars.where(calendar_state: :idle).count.to_s, color: :success
      )
      InfoCard(
        icon: :warning, label: t('admin.labels.issues'),
        value: error_count.to_s, color: error_count.positive? ? :error : :neutral
      )
    end
  end

  def render_calendars_table # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'card bg-base-100 border border-base-300') do
      div(class: 'card-body p-0') do
        div(class: 'p-4 border-b border-base-300 flex items-center justify-between') do
          h2(class: 'font-bold flex items-center gap-2') do
            icon(:calendar, size: '5')
            plain 'Calendars'
            span(class: 'badge badge-neutral') { calendars.count.to_s }
          end
        end

        if calendars.any?
          div(class: 'overflow-x-auto') do
            table(class: 'table table-sm') do
              render_table_head
              tbody { calendars.each { |cal| render_calendar_row(cal) } }
            end
          end
        else
          EmptyState(
            icon: :calendar, message: t('admin.sites.show.empty.title'),
            hint: t('admin.sites.show.empty.hint'), icon_size: '12', padding: 'py-12'
          )
        end
      end
    end
  end

  def render_table_head
    thead do
      tr do
        th { t('admin.table.name') }
        th { t('admin.table.state') }
        th { t('admin.table.last_import') }
        th { t('admin.table.last_changed') }
      end
    end
  end

  def render_calendar_row(calendar) # rubocop:disable Metrics/AbcSize
    tr(class: 'hover') do
      td do
        div(class: 'flex flex-col') do
          link_to calendar.name, edit_admin_calendar_path(calendar),
                  class: 'font-medium text-base-content hover:text-placecal-orange'
          span(class: 'text-xs text-gray-600 font-mono') { "##{calendar.id}" }
        end
      end
      td { render_calendar_state(calendar) }
      td(class: 'whitespace-nowrap') { render_time_ago(calendar.last_import_at) }
      td(class: 'whitespace-nowrap') { render_time_ago(calendar.checksum_updated_at) }
    end
  end

  def render_calendar_state(calendar) # rubocop:disable Metrics/MethodLength
    case calendar.calendar_state.to_s
    when 'idle'
      span(class: 'inline-flex items-center gap-1 text-success', title: 'Ready') { icon(:check, size: '4') }
    when 'in_queue', 'in_worker'
      span(class: 'inline-flex items-center gap-1 text-info', title: 'Processing') do
        icon(:swap, size: '4', css_class: 'animate-spin')
      end
    when 'error', 'bad_source'
      span(class: 'inline-flex items-center gap-1 text-error',
           title: calendar.calendar_state.to_s.titleize) { icon(:warning, size: '4') }
    else
      span(class: 'text-gray-500') { "\u2014" }
    end
  end

  def render_time_ago(timestamp)
    if timestamp
      span(class: 'text-sm text-base-content/70',
           title: timestamp.strftime('%d %b %Y at %H:%M')) { "#{time_ago_in_words(timestamp)} ago" }
    else
      span(class: 'text-gray-500') { "\u2014" }
    end
  end
end
