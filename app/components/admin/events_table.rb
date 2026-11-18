# frozen_string_literal: true

class Components::Admin::EventsTable < Components::Admin::Base
  include Phlex::Rails::Helpers::Truncate

  prop :events, _Interface(:each), reader: :private
  # Past events show their year where upcoming ones show their time
  prop :past, _Boolean, default: false, reader: :private

  def view_template
    div(class: 'overflow-x-auto') do
      table(class: 'table table-sm') do
        thead do
          tr do
            th(class: 'w-24') { t('admin.events_table.date') }
            th { t('admin.events_table.event') }
            th { t('admin.events_table.location') }
            th { t('admin.events_table.source_categories') }
            th { t('admin.events_table.source_organiser') }
          end
        end
        tbody { events.each { |event| render_row(event) } }
      end
    end
  end

  private

  def render_row(event)
    tr(class: 'hover') do
      td(class: 'whitespace-nowrap') do
        div(class: 'font-semibold text-sm') { event.dtstart.strftime('%d %b') }
        div(class: 'text-xs text-gray-600') { event.dtstart.strftime(past ? '%Y' : '%H:%M') }
      end
      td do
        link_to truncate(event.summary, length: 70), admin_event_path(event), class: 'font-medium link link-hover'
      end
      td(class: 'text-sm text-base-content/70') { render_location(event) }
      td(class: 'text-sm text-base-content/70') { render_source_value(Array(event.source_categories).join(', ')) }
      td(class: 'text-sm text-base-content/70') { render_source_value(event.source_organiser) }
    end
  end

  def render_source_value(value)
    if value.present?
      span(title: (value if value.length > 50)) { truncate(value, length: 50) }
    else
      span(class: 'text-gray-600') { t('admin.events_table.not_in_source') }
    end
  end

  def render_location(event)
    if event.address
      plain truncate(event.address.to_s, length: 50)
    elsif event.organiser
      plain event.organiser.name
    else
      span(class: 'text-gray-600') { t('admin.events_table.no_location') }
    end
  end
end
