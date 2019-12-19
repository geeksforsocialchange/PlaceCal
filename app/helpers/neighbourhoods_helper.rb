# frozen_string_literal: true

module NeighbourhoodsHelper
  def options_for_users
    User.all.order(:last_name).collect { |e| [e.admin_name, e.id] }
  end
end
