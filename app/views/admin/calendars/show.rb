# frozen_string_literal: true

class Views::Admin::Calendars::Show < Views::Admin::Base
  prop :calendar, Calendar, reader: :private

  def view_template
    render_header
    render Views::Admin::Calendars::ImporterOverview.new(calendar:)
    div(class: 'divider my-6')
    render_info_cards
    render_events_section
  end

  private

  def render_header
    div(class: 'mb-6') do
      div(class: 'flex flex-wrap items-center justify-between gap-4') do
        div do
          h1(class: 'text-2xl font-bold') { calendar.name }
          p(class: 'text-sm text-gray-600 mt-1') do
            plain 'Calendar for '
            link_to calendar.organiser.name, edit_admin_partner_path(calendar.organiser),
                    class: 'link link-hover text-placecal-orange-dark'
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

  def render_info_cards
    div(class: 'grid grid-cols-1 md:grid-cols-3 gap-4 mb-8') do
      InfoCard(icon: :partner, label: 'Partner', color: :orange) do
        link_to calendar.organiser.name, edit_admin_partner_path(calendar.organiser),
                class: 'font-semibold link link-hover text-placecal-orange-dark'
      end
      InfoCard(
        icon: :cog, label: 'Strategy', value: calendar.strategy.to_s.titleize, color: :info
      )
      InfoCard(icon: :map_pin, label: 'Default Location', color: :success) do
        if calendar.place
          link_to calendar.place.name, edit_admin_partner_path(calendar.place),
                  class: 'font-semibold link link-hover text-placecal-orange-dark'
        end
      end
    end
  end

  def render_events_section
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

  def render_upcoming_tab(upcoming)
    input(type: 'radio', name: 'events_tabs', class: 'tab',
          aria_label: t('admin.calendars.show.upcoming_tab', count: upcoming.count), checked: true)
    div(role: 'tabpanel', class: 'tab-content py-4') do
      if upcoming.any?
        render_events_table(upcoming, :upcoming)
      else
        EmptyState(icon: :calendar, message: 'No upcoming events',
                   icon_size: '12', padding: 'py-12')
      end
    end
  end

  def render_past_tab(past)
    input(type: 'radio', name: 'events_tabs', class: 'tab',
          aria_label: t('admin.calendars.show.past_tab', count: past.count))
    div(role: 'tabpanel', class: 'tab-content py-4') do
      if past.any?
        render_events_table(past, :past)
        total_past = calendar.events.past.count
        p(class: 'text-center text-sm text-gray-600 mt-4') { "Showing 50 of #{total_past} past events" } if total_past > 50
      else
        EmptyState(icon: :calendar, message: 'No past events',
                   icon_size: '12', padding: 'py-12')
      end
    end
  end

  def render_events_table(events, type)
    EventsTable(events:, past: type == :past)
  end
end
