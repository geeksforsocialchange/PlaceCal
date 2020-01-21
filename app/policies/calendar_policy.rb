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

      cals = Calendar.none
      if user.neighbourhood_admin?
        cals += Calendar.joins(partner: :address, place: :address)
                        .where(addresses: { neighbourhood_id: user.neighbourhood_ids })
      end
      if user.partner_admin?
        cals += Calendar.where("partner_id = :partner_ids OR place_id = :partner_ids",
                               partner_ids: user.partner_ids)
      end
      cals.uniq
    end
  end
end
