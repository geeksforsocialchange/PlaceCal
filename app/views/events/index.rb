# frozen_string_literal: true

class Views::Events::Index < Views::Base
  prop :events, Hash, reader: :private
  prop :period, String, reader: :private
  prop :sort, String, reader: :private
  prop :repeating, String, reader: :private
  prop :current_day, Date, reader: :private
  prop :site, Site, reader: :private
  prop :selected_neighbourhood, _Nilable(String), reader: :private
  prop :next_date, _Nilable(::Event), reader: :private
  prop :truncated, _Boolean, reader: :private
  prop :show_monthly, _Boolean, reader: :private, default: true

  def view_template
    content_for(:title) { 'Events' }
    content_for(:image) { site.og_image }
    content_for(:description) { site.og_description }

    Hero('Events & activities', site.tagline)

    div(class: 'c c--lg-space-after') do
      turbo_frame_tag 'events-browser', data: { turbo_action: 'advance' } do
        render_paginator
        hr
        render_event_list
      end
    end

    render_meta_section
  end

  private

  def render_paginator
    div(class: 'paginator', id: 'paginator') do
      div(class: 'paginator__context') do
        Breadcrumb(trail: [['Events', events_path]], site_name: site.name) do
          div(class: 'breadcrumb__actions contents') do
            today = Time.zone.today
            today_url = "/events/#{today.year}/#{today.month}/#{today.day}?period=#{period}&sort=#{sort}&repeating=#{repeating}#paginator"
            EventFilter(
              pointer: current_day,
              period: period,
              sort: sort,
              repeating: repeating,
              today_url: today_url,
              today: current_day == today,
              site: site,
              selected_neighbourhood: selected_neighbourhood,
              show_monthly: show_monthly
            )
          end
        end
      end
      Timeline(
        pointer: current_day,
        period: period,
        sort: sort,
        repeating: repeating,
        path: 'events'
      )
    end
  end

  def render_event_list
    EventList(
      events: events,
      period: period,
      primary_neighbourhood: site.primary_neighbourhood,
      show_neighbourhoods: site.show_neighbourhoods?,
      badge_zoom_level: site.badge_zoom_level&.to_s,
      next_date: next_date&.dtstart,
      site_tagline: site.tagline,
      truncated: truncated
    )
  end

  def render_meta_section
    Meta('/hello/world') do |component|
      component.with_link do
        link_to "Subscribe to #{site.name} with iCal", events_url(protocol: :webcal, format: :ics)
      end
    end
  end
end
