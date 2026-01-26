# frozen_string_literal: true

# Renders a list of events grouped by date
# Used by EventsBrowserComponent and partner/place pages
class EventListComponent < ViewComponent::Base
  attr_reader :events, :period, :primary_neighbourhood, :show_neighbourhoods,
              :badge_zoom_level, :site_tagline, :next_url

  # rubocop:disable Metrics/ParameterLists
  def initialize(events:, period: 'day', primary_neighbourhood: nil,
                 show_neighbourhoods: false, badge_zoom_level: nil,
                 site_tagline: nil, next_url: nil)
    # rubocop:enable Metrics/ParameterLists
    super()
    @events = events
    @period = period
    @primary_neighbourhood = primary_neighbourhood
    @show_neighbourhoods = show_neighbourhoods
    @badge_zoom_level = badge_zoom_level
    @site_tagline = site_tagline
    @next_url = next_url
  end

  def events?
    events.any?
  end
end
