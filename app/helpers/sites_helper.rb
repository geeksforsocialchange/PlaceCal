# frozen_string_literal: true

module SitesHelper
  def options_for_sites_neighbourhoods(for_site)
    legacy_neighbourhoods = for_site.neighbourhoods.where.not(release_date: Neighbourhood::LATEST_RELEASE_DATE)

    scope = Neighbourhood.find_latest_neighbourhoods_maybe_with_legacy_neighbourhoods(@all_neighbourhoods, legacy_neighbourhoods)

    scope
      .order(:name)
      .all
      .collect do |ward|
        name = ward.contextual_name
        name += " - #{ward.release_date.year}/#{ward.release_date.month}" if ward.legacy_neighbourhood?

        { name: name, id: ward.id }
      end
  end

  def options_for_tags
    policy_scope(Tag)
      .select(:name, :type, :id)
      .order(:name)
      .map { |r| [r.name_with_type, r.id] }
  end
end
