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

    if user.neighbourhood_admin?
      user.neighbourhood_ids.include?(record.neighbourhood_id)
    else
      user.partner_ids.include?(record.id)
    end
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

  class Scope < Scope
    def resolve
      if user.root?
        scope.all
      elsif user.tag_admin?
        scope.joins(:tags).where(tags: { id: user.tags }).distinct
      elsif user.partner_admin?
        scope.joins(:users).where(partners_users: { user_id: user.id })
      elsif user.neighbourhood_admin?
        scope.joins(:address).where(addresses: { neighbourhood_id: user.neighbourhood_ids })
      else
        scope.none
      end
    end
  end
end
