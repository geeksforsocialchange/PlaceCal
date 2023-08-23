# frozen_string_literal: true

module NeighbourhoodsHelper
  def options_for_users
    User.all.order(:last_name).collect { |e| [e.admin_name, e.id] }
  end

  def safe_neighbourhood_name(neighbourhood)
    return neighbourhood.name if neighbourhood.name.present?

    "[untitled #{neighbourhood.id}]"
  end

  def link_to_neighbourhood(neighbourhood)
    text = neighbourhood.name
    text += " - (#{neighbourhood.release_date.year}/#{neighbourhood.release_date.month})" if neighbourhood.legacy_neighbourhood?

    html = link_to(text, edit_admin_neighbourhood_path(neighbourhood))
    html.html_safe # rubocop:disable Rails/OutputSafety
  end
end
