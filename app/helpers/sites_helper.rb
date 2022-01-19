# frozen_string_literal: true

module SitesHelper
  def options_for_sites_neighbourhoods
    Neighbourhood.all.order(:name).filter { |e| e.name != '' }.collect { |e| [e.name, e.id] }
  end
end
