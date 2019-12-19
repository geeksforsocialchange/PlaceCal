# frozen_string_literal: true

module PartnersHelper
  def options_for_partners
    Partner.all.order(:name).pluck(:name, :id)
  end

  def options_for_neighbourhoods
    Neighbourhood.all.order(:name).pluck(:name, :id)
  end
end
