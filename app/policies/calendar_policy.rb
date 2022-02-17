# frozen_string_literal: true

class CalendarPolicy < ApplicationPolicy
  def index?
    user.root? || user.neighbourhood_admin? || user.partner_admin?
  end

  def create?
    index?
  end

  def new?
    index?
  end

  def edit?
    index?
  end

  def update?
    return true if user.root?
    return true if user.partner_admin? && user.partner_ids.include?(record.partner_id)
    # return true if user.neighbourhood_admin? && user.neighbourhoods.include?(record.address.neighbourhood)
    index?
  end

  def import?
    index?
  end

  def select_page?
    index?
  end

  def destroy?
    index?
  end

  class Scope < Scope
    def resolve
      return scope.all if user.root?
      return scope.none if !user.partner_admin? && !user.neighbourhood_admin?

      Calendar.left_outer_joins(partner: :address, place: :address)
              .where(addresses: { neighbourhood_id: user.owned_neighbourhood_ids })
              .or(Calendar.left_outer_joins(partner: :address, place: :address)
              .where("partner_id IN (:partner_id) OR place_id IN (:partner_id)", partner_id: user.partner_ids))
              .distinct
    end
  end
end
