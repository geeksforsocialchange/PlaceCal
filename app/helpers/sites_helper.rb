# frozen_string_literal: true

module SitesHelper
  def options_for_tags
    policy_scope(Tag)
      .select(:name, :type, :id)
      .order(:name)
      .map { |r| [r.name_with_type, r.id] }
  end
end
