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
    if user.root?
      [
        :id,
        :name,
        :place_name,
        :is_published,
        :tagline,
        :slug,
        :description,
        :domain,
        :logo,
        :footer_logo,
        :theme,
        :hero_image,
        :hero_image_credit,
        :site_admin_id,
        sites_neighbourhoods_attributes: %i[_destroy id neighbourhood_id relation_type],
        sites_neighbourhood_attributes: %i[_destroy id neighbourhood_id relation_type]
      ]
    else
      [
        :id,
        :name,
        :place_name,
        :is_published,
        :tagline,
        :description,
        :hero_image,
        :hero_image_credit,
        sites_neighbourhoods_attributes: %i[_destroy id neighbourhood_id relation_type],
        sites_neighbourhood_attributes: %i[_destroy id neighbourhood_id relation_type]
      ]
    end
  end

  class Scope < Scope
    def resolve
      if user.root?
        scope.all
      elsif user.site_admin?
        scope.where(site_admin: user)
      else
        scope.none
      end
    end
  end
end
