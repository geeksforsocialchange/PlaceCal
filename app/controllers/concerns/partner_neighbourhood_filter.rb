# frozen_string_literal: true

class PartnerNeighbourhoodFilter
  attr_reader :neighbourhoods, :neighbourhood_names

  def initialize(current_site, neighbourhood_names, params)
    @current_neighbourhood_name = params[:neighbourhood_name]
    @neighbourhood_names = neighbourhood_names
    @badge_zoom_level = current_site.badge_zoom_level
  end

  def active?
    @current_neighbourhood_name.present?
  end

  def current_neighbourhood_name?(neighbourhood_name)
    @current_neighbourhood_name.present? && (@current_neighbourhood_name == neighbourhood_name)
  end

  def apply_to(query = Partner)
    return query unless active?

    query.for_neighbourhood_name_filter(query, @badge_zoom_level, @current_neighbourhood_name)
  end

  def render_filter(view)
    view.render partial: 'partners/neighbourhood_filter', locals: { filter: self }
  end

  def reset(url)
    url.sub(/(&|)neighbourhood_name=\d*/, '')
  end
end
