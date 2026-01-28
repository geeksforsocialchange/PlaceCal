# frozen_string_literal: true

class EventFilterComponent < ViewComponent::Base
  attr_reader :pointer, :period, :sort, :repeating, :today_url

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

    @neighbourhoods ||= EventsQuery.new(site: @site).neighbourhoods_with_counts
  end

  def neighbourhood_selected?(id)
    @selected_neighbourhood == id
  end

  def show_neighbourhood_filter?
    neighbourhoods.any?
  end

  def neighbourhood_filter_active?
    @selected_neighbourhood.positive?
  end
end
