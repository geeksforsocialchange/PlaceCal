# frozen_string_literal: true

class PartnerPolicy < ApplicationPolicy
  def index?
    user.neighbourhood_admin? || user.partner_admin?
  end

  def show?
    index?
  end

  def create?
    user.neighbourhood_admin?
  end

  def new?
    create?
  end

  def update?
    return true if user.neighbourhood_admin?

    user.partner_ids.include?(record.id)
  end

  def edit?
    update?
  end

  def destroy?
    user.neighbourhood_admin?
  end

  class Scope < Scope
    def resolve
      if user.root?
        scope.all
      elsif user.tag_admin?
        scope.joins(:tags).where(tags: { id: user.tags }).distinct
      elsif user.partner_admin?
        scope.joins(:users).where(partners_users: { user_id: user.id })
      else
        scope.none
      end
    end
  end
end
