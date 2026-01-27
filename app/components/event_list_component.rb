# frozen_string_literal: true

class EventListComponent < ViewComponent::Base
  # rubocop:disable Metrics/ParameterLists
  def initialize(events:, period:, primary_neighbourhood: nil, show_neighbourhoods: false,
                 badge_zoom_level: nil, next_date: nil, site_tagline: nil, truncated: false)
    # rubocop:enable Metrics/ParameterLists
    super()
    @events = events
    @period = period
    @primary_neighbourhood = primary_neighbourhood
    @show_neighbourhoods = show_neighbourhoods
    @badge_zoom_level = badge_zoom_level
    @next_date = next_date
    @site_tagline = site_tagline
    @truncated = truncated
  end

  attr_reader :events, :period, :primary_neighbourhood, :show_neighbourhoods,
              :badge_zoom_level, :next_date, :site_tagline, :truncated
end
