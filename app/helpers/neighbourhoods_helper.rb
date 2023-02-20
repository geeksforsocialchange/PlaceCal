# frozen_string_literal: true

module NeighbourhoodsHelper
  def options_for_users
    User.all.order(:last_name).collect { |e| [e.admin_name, e.id] }
  end

  def safe_neighbourhood_name(neighbourhood)
    return neighbourhood.name if neighbourhood.name.present?

    "[untitled #{neighbourhood.id}]"
  end
end
