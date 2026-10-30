# frozen_string_literal: true

class Views::Sites::Events::Index < Views::Base
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
  prop :query, _Nilable(::EventsQuery), reader: :private, default: nil

  def view_template
    content_for(:title) { t('events.index.page_title') }
    content_for(:description) { site.og_description }

    Shared::Hero(t('events.index.title'), site.tagline, standfirst: t('events.index.standfirst'))

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

  def day_strip?
    Current.theme.event_filter_style != :date_picker
  end

  def render_paginator
    div(class: 'paginator leading-snug print:hidden', id: 'paginator') do
      div(class: 'paginator__context') do
        Sites::Breadcrumb(trail: [[t('navigation.site.events'), events_path]], site_name: site.name) do
          # A day strip is wider than the row, so it scrolls inside it and the sort filter wraps underneath.
          UI::Cluster(gap: :sm, wrap: day_strip?, class: day_strip? ? 'filter-bar min-w-0 max-w-full' : 'filter-bar') do
            today = Time.zone.today
            region_param = selected_region ? "&region=#{selected_region.slug}" : ''
            today_url = "/events/#{today.year}/#{today.month}/#{today.day}?period=#{period}&sort=#{sort}&repeating=#{repeating}#{region_param}#paginator"
            Sites::EventFilter(
              pointer: current_day,
              period:,
              sort:,
              repeating:,
              today_url:,
              today: current_day == today,
              site:,
              selected_neighbourhood:,
              show_monthly:,
              region_tags:,
              selected_region:,
              query:
            )
          end
        end
      end
      Sites::Timeline(
        pointer: current_day,
        period:,
        sort:,
        repeating:,
        path: 'events'
      )
    end
  end

  def render_event_list
    Sites::EventList(
      events:,
      period:,
      show_neighbourhoods: site.show_neighbourhoods?,
      badge_zoom_level: site.badge_zoom_level&.to_s,
      next_date: next_date&.dtstart,
      site_tagline: site.tagline,
      truncated:
    )
  end

  def render_meta_section
    Sites::Meta() do |component|
      component.with_link do
        link_to t('events.index.subscribe_ical', name: site.name), events_url(protocol: :webcal, format: :ics), class: Sites::Meta::LINK
        link_to t('events.csv_export.link'), events_url(format: :csv, **csv_export_params), class: Sites::Meta::LINK
      end
    end
  end

  # Carries the current view's filters into the CSV export, so the download
  # matches whatever the visitor is looking at rather than the whole site.
  def csv_export_params
    params = { period:, sort:, repeating: }
    params[:region] = selected_region.slug if selected_region
    params[:neighbourhood] = selected_neighbourhood if selected_neighbourhood.present?
    params
  end
end
