# frozen_string_literal: true

# Main orchestrating component for the events browser
# Consolidates state management and URL building for events navigation
class EventsBrowserComponent < ViewComponent::Base
  attr_reader :events, :current_day, :period, :sort, :repeating, :site,
              :next_date, :primary_neighbourhood, :show_neighbourhoods,
              :badge_zoom_level, :site_tagline

  # rubocop:disable Metrics/ParameterLists
  def initialize(events:, current_day:, period:, sort:, repeating:, site:,
                 next_date:, primary_neighbourhood: nil, show_neighbourhoods: false,
                 badge_zoom_level: nil, site_tagline: nil)
    # rubocop:enable Metrics/ParameterLists
    super()
    @events = events
    @current_day = current_day
    @period = period || 'day'
    @sort = sort || 'time'
    @repeating = repeating || 'on'
    @site = site
    @next_date = next_date
    @primary_neighbourhood = primary_neighbourhood
    @show_neighbourhoods = show_neighbourhoods
    @badge_zoom_level = badge_zoom_level
    @site_tagline = site_tagline
  end

  # Generates URL for events with given parameters
  # Used by pagination and filters to build navigation links
  def events_path_for(day: nil, **overrides)
    target_day = day || current_day
    params = url_params.merge(overrides.compact)

    "/events/#{target_day.year}/#{target_day.month}/#{target_day.day}?#{params.to_query}"
  end

  # Returns URL for the next date with events
  def next_events_url
    return nil unless next_date

    events_path_for(
      day: next_date.dtstart.to_date,
      period: period,
      sort: sort,
      repeating: repeating
    )
  end

  # Step size for pagination (1 day or 1 week)
  def step
    period == 'week' ? 1.week : 1.day
  end

  # Whether to show the paginator (not shown for 'future' period)
  def show_paginator?
    %w[day week].include?(period)
  end

  # Adjusted pointer for week view (start of week)
  def pointer
    period == 'week' ? current_day.beginning_of_week : current_day
  end

  private

  def url_params
    {
      period: period,
      sort: sort,
      repeating: repeating
    }
  end
end
