# frozen_string_literal: true

class CalendarPolicy < ApplicationPolicy
  def index?
    user.neighbourhood_admin? || user.partner_admin?
  end

  def create?
    index?
  end

  def new?
    index?
  end

  def edit?
    return true if user.neighbourhood_admin?

    user.partner_admin? &&
      user.partner_ids.include?(record.partner_id)
  end

  def update?
    edit?
  end

  def import?
    user.root?
  end

  def select_page?
    index?
  end

  def destroy?
    user.root?
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
