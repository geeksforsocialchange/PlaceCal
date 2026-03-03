# frozen_string_literal: true

class Views::Admin::Calendars::Show < Views::Admin::Base # rubocop:disable Metrics/ClassLength
  include Phlex::Rails::Helpers::Truncate

  prop :calendar, _Any, reader: :private

  def view_template
    render_header
    render Views::Admin::Calendars::ImporterOverview.new(calendar: calendar)
    div(class: 'divider my-6')
    render_info_cards
    render_events_section
  end

  private

  def render_header # rubocop:disable Metrics/AbcSize
    div(class: 'mb-6') do
      div(class: 'flex flex-wrap items-center justify-between gap-4') do
        div do
          h1(class: 'text-2xl font-bold') { calendar.name }
          p(class: 'text-sm text-gray-600 mt-1') do
            plain 'Calendar for '
            link_to calendar.partner.name, edit_admin_partner_path(calendar.partner),
                    class: 'link link-hover text-placecal-orange'
          end
        end
        div(class: 'flex items-center gap-2') do
          link_to(edit_admin_calendar_path(calendar.id),
                  class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange') do
            icon(:edit, size: '4')
            plain 'Edit Calendar'
          end
        end
      end
    end
  end

  def render_info_cards # rubocop:disable Metrics/AbcSize
    div(class: 'grid grid-cols-1 md:grid-cols-3 gap-4 mb-8') do
      render(Components::Admin::InfoCard.new(icon: :partner, label: 'Partner', color: :orange)) do
        link_to calendar.partner.name, edit_admin_partner_path(calendar.partner),
                class: 'font-semibold link link-hover text-placecal-orange'
      end
      render Components::Admin::InfoCard.new(
        icon: :cog, label: 'Strategy', value: calendar.strategy.to_s.titleize, color: :info
      )
      render(Components::Admin::InfoCard.new(icon: :map_pin, label: 'Default Location', color: :success)) do
        if calendar.place
          link_to calendar.place.name, edit_admin_partner_path(calendar.place),
                  class: 'font-semibold link link-hover text-placecal-orange'
        end
      end
    end
  end

  def render_events_section # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    upcoming = calendar.events.upcoming
    past = calendar.events.past.limit(50)

    div(class: 'card bg-base-100 border border-base-300') do
      div(class: 'card-body p-0') do
        div(class: 'p-4 border-b border-base-300 flex items-center justify-between') do
          h2(class: 'font-bold flex items-center gap-2') do
            icon(:event, size: '5')
            plain 'Events'
            span(class: 'badge badge-neutral') { calendar.events.count.to_s }
          end
        end

        div(class: 'tabs tabs-bordered px-4 pt-2') do
          render_upcoming_tab(upcoming)
          render_past_tab(past)
        end
      end
    end
  end

  def render_upcoming_tab(upcoming) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    input(type: 'radio', name: 'events_tabs', role: 'tab', class: 'tab',
          aria_label: "Upcoming (#{upcoming.count})", checked: true)
    div(role: 'tabpanel', class: 'tab-content py-4') do
      if upcoming.any?
        render_events_table(upcoming, :upcoming)
      else
        render Components::Admin::EmptyState.new(icon: :calendar, message: 'No upcoming events',
                                                 icon_size: '12', padding: 'py-12')
      end
    end
  end

  def render_past_tab(past) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    input(type: 'radio', name: 'events_tabs', role: 'tab', class: 'tab',
          aria_label: "Past (#{past.count})")
    div(role: 'tabpanel', class: 'tab-content py-4') do
      if past.any?
        render_events_table(past, :past)
        total_past = calendar.events.past.count
        p(class: 'text-center text-sm text-gray-600 mt-4') { "Showing 50 of #{total_past} past events" } if total_past > 50
      else
        render Components::Admin::EmptyState.new(icon: :calendar, message: 'No past events',
                                                 icon_size: '12', padding: 'py-12')
      end
    end
  end

  def render_events_table(events, type) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'overflow-x-auto') do
      table(class: 'table table-sm') do
        thead do
          tr do
            th(class: 'w-24') { 'Date' }
            th { 'Event' }
            th { 'Location' }
          end
        end
        tbody do
          events.each { |event| render_event_row(event, type) }
        end
      end
    end
  end

  def render_event_row(event, type) # rubocop:disable Metrics/AbcSize
    tr(class: "hover#{' opacity-70' if type == :past}") do
      td(class: 'whitespace-nowrap') do
        div(class: 'font-semibold text-sm') { event.dtstart.strftime('%d %b') }
        div(class: 'text-xs text-gray-600') do
          plain type == :past ? event.dtstart.strftime('%Y') : event.dtstart.strftime('%H:%M')
        end
      end
      td { div(class: 'font-medium') { truncate(event.summary, length: 70) } }
      td(class: 'text-sm text-base-content/70') { render_event_location(event) }
    end
  end

  def render_event_location(event)
    if event.address
      plain truncate(event.address.to_s, length: 50)
    elsif event.partner
      plain event.partner.name
    else
      span(class: 'text-gray-500') { "\u2014" }
    end
  end
end
