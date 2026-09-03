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
  prop :region_tags, Array, reader: :private, default: -> { [] }
  prop :selected_region, _Nilable(::Tag), reader: :private, default: nil

  def view_template
    content_for(:title) { t('events.index.page_title') }
    content_for(:description) { site.og_description }

    Hero(t('events.index.title'), site.tagline, standfirst: t('events.index.standfirst'))

    div(class: 'container-public mb-32') do
      list_heading('events.index.list_heading')
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
        Breadcrumb(trail: [[t('navigation.site.events'), events_path]], site_name: site.name) do
          div(class: 'breadcrumb__actions') do
            today = Time.zone.today
            region_param = selected_region ? "&region=#{selected_region.slug}" : ''
            today_url = "/events/#{today.year}/#{today.month}/#{today.day}?period=#{period}&sort=#{sort}&repeating=#{repeating}#{region_param}#paginator"
            EventFilter(
              pointer: current_day,
              period: period,
              sort: sort,
              repeating: repeating,
              today_url: today_url,
              today: current_day == today,
              site: site,
              selected_neighbourhood: selected_neighbourhood,
              show_monthly: show_monthly,
              region_tags: region_tags,
              selected_region: selected_region
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
