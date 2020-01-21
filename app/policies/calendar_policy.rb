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
      if user.root?
        scope.all
      else
        scope.joins(partner: :users).where(partners_users: { user_id: user.id })
      end
    end
  end
end
