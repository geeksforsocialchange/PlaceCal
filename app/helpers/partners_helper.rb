# frozen_string_literal: true

module PartnersHelper

  def options_for_service_area_neighbourhoods
    # Remove the primary neighbourhood from the list
    @all_neighbourhoods.filter { |e| e.name != '' }
                       .collect { |e| { name: e.contextual_name, id: e.id } }
  end
end
