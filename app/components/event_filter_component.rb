# frozen_string_literal: true

class EventFilterComponent < ViewComponent::Base
  include SvgIconsHelper

  attr_reader :pointer, :period, :sort, :repeating, :today_url, :selected_neighbourhood

  # rubocop:disable Metrics/ParameterLists
  def initialize(pointer:, period:, sort:, repeating:, today_url:, today: false, site: nil, selected_neighbourhood: nil)
    super()
    @pointer = pointer
    @period = period
    @sort = sort || 'time'
    @repeating = repeating
    @today_url = today_url
    @today = today
    @site = site
    @selected_neighbourhood = selected_neighbourhood.to_i
  end
  # rubocop:enable Metrics/ParameterLists

  def today?
    @today
  end

  def neighbourhoods
    return [] unless @site

    @neighbourhoods ||= EventsQuery.new(site: @site).neighbourhoods_with_counts(period: @period)
  end

  def neighbourhood_items
    neighbourhoods.map do |n|
      { id: n[:neighbourhood].id, name: n[:neighbourhood].name, count: n[:count] }
    end
  end

  def show_neighbourhood_filter?
    neighbourhoods.length > 1
  end
end
