# frozen_string_literal: true

class PartnerPolicy < ApplicationPolicy
  def index?
    user.root? || user.neighbourhood_admin? || user.partner_admin?
  end

  def show?
    update?
  end

  def create?
    user.root? || user.neighbourhood_admin?
  end

  def new?
    create?
  end

  def update?
    return true if user.root?

    user.neighbourhood_ids.include?(record.neighbourhood_id) ||
      user.partner_ids.include?(record.id)
  end

  def edit?
    update?
  end

  def destroy?
    return true if user.root?
    return false unless user.neighbourhood_admin?

    user.neighbourhood_ids.include?(record.neighbourhood_id)
  end

  def setup?
    create?
  end

  def permitted_attributes
    attrs = [ :name, :image, :summary, :description,
              :public_name, :public_email, :public_phone,
              :partner_name, :partner_email, :partner_phone,
              :address_id, :url, :facebook_link, :twitter_handle,
              :opening_times,
              calendars_attributes: %i[id name source strategy place_id partner_id _destroy],
              address_attributes: %i[street_address street_address2 street_address3 city postcode],
              service_area_attributes: %i[neighbourhood_id],
              tag_ids: [] ]

    attrs << :slug if user.root?
    attrs
  end

  class Scope < Scope
    def resolve
      if user.root?
        scope.all
      else
        scope.left_outer_joins(:users, :address)
             .where("partners_users.user_id = ? OR addresses.neighbourhood_id IN (?)", user.id, user.neighbourhood_ids)
             .distinct
      end
    end
  end
end
