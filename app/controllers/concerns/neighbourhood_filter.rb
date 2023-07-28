# frozen_string_literal: true

class NeighbourhoodFilter
  attr_reader :neighbourhoods

  def initialize(neighbourhoods, params)
    @current_neighbourhood = Neighbourhood.find_by(id: params[:neighbourhood])
    @neighbourhoods = neighbourhoods
  end

  def active?
    @current_neighbourhood.present?
  end

  def current_neighbourhood?(neighbourhood)
    @current_neighbourhood.present? && (@current_neighbourhood.id == neighbourhood.id)
  end

  def render_filter(view)
    view.render partial: 'events/neighbourhood_filter', locals: { filter: self }
  end

  def reset(url)
    url.sub(/(&|)neighbourhood=\d*/, '')
  end
end
