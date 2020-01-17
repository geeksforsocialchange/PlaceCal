# frozen_string_literal: true

module PartnersHelper
  def options_for_partners
    policy_scope(Partner).all.order(:name).pluck(:name, :id)
  end

  def options_for_neighbourhoods
    Neighbourhood.all.order(:name).pluck(:name, :id)
  end
end
