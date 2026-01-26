# frozen_string_literal: true

class EventListComponent < ViewComponent::Base
  # rubocop:disable Metrics/ParameterLists
  def initialize(events:, pointer:, period:, sort: nil, path: nil, repeating: nil,
                 show_breadcrumb: true, show_paginator: true, site_name: nil,
                 primary_neighbourhood: nil, show_neighbourhoods: false,
                 badge_zoom_level: nil, next_date: nil, site_tagline: nil)
    # rubocop:enable Metrics/ParameterLists
    super()
    @events = events
    @pointer = pointer
    @period = period
    @sort = sort
    @path = path
    @repeating = repeating
    @show_breadcrumb = show_breadcrumb
    @show_paginator = show_paginator
    @site_name = site_name
    @primary_neighbourhood = primary_neighbourhood
    @show_neighbourhoods = show_neighbourhoods
    @badge_zoom_level = badge_zoom_level
    @next_date = next_date
    @site_tagline = site_tagline
  end

  attr_reader :events, :pointer, :period, :sort, :path, :repeating,
              :show_breadcrumb, :show_paginator, :site_name,
              :primary_neighbourhood, :show_neighbourhoods, :badge_zoom_level, :next_date, :site_tagline
end
