# frozen_string_literal: true

class NeighbourhoodFilter
  attr_reader :neighbourhoods

  def initialize(current_site, neighbourhoods, params)
    @current_neighbourhood = Neighbourhood.find_by(id: params[:neighbourhood])
    @neighbourhoods = neighbourhoods
    @badge_zoom_level = current_site.badge_zoom_level
  end

  def active?
    @current_neighbourhood.present?
  end

  def current_neighbourhood?(neighbourhood)
    @current_neighbourhood.present? && (@current_neighbourhood.id == neighbourhood.id)
  end

  def apply_to_partner(query = Partner)
    return query unless active?

    neighbourhoods = if @current_neighbourhood.descendants.any?
                       @current_neighbourhood.descendants.map(&:id) << @current_neighbourhood.id
                     else
                       [@current_neighbourhood.id]
                     end

    query
      .joins('left join addresses on partners.address_id = addresses.id')
      .joins('left join service_areas on service_areas.partner_id = partners.id')
      .where('(addresses.neighbourhood_id IN (:neighbourhoods)) OR (service_areas.neighbourhood_id IN (:neighbourhoods))', neighbourhoods: neighbourhoods)
  end

  def render_filter(view)
    view.render partial: 'partners/neighbourhood_filter', locals: { filter: self }
  end

  def reset(url)
    url.sub(/(&|)neighbourhood=\d*/, '')
  end
end
