# frozen_string_literal: true

class SitePolicy < ApplicationPolicy
  def index?
    user.root? || user.site_admin?
  end

  def new?
    user.root?
  end

  def create?
    user.root?
  end

  def edit?
    user.root? || user.site_admin?
  end

  def update?
    user.root? || user.site_admin?
  end

  def destroy?
    user.root?
  end

  def permitted_attributes
    attrs = %i[id name place_name is_published tagline description
               badge_zoom_level hero_image hero_image_credit]
            .push(sites_neighbourhoods_attributes: %i[_destroy id neighbourhood_id relation_type],
                  sites_neighbourhood_attributes: %i[_destroy id neighbourhood_id relation_type],
                  tag_ids: [])

    root_attrs = %i[slug domain logo footer_logo theme site_admin_id]

    return root_attrs + attrs if user.root?

    attrs
  end

  class Scope < Scope
    def resolve
      if user.site_admin?
        scope.where(site_admin: user)
      elsif user.root?
        scope.all
      else
        scope.none
      end
    end
  end
end
