# frozen_string_literal: true

module SitesHelper
  def options_for_sites_neighbourhoods
    # Remove the primary neighbourhood from the list
    @all_neighbourhoods.filter { |e| e.name != '' }.collect { |e| [e.shortname, e.id] }
  end
end
