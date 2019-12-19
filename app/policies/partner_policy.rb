# frozen_string_literal: true

class PartnerPolicy < ApplicationPolicy
  def index?
    user.secretary? || user.partner_admin?
  end

  def show?
    index?
  end

  def create?
    user.secretary?
  end

  def new?
    create?
  end

  def update?
    return true if user.secretary?

    user.partner_ids.include?(record.id)
  end

  def edit?
    update?
  end

  def destroy?
    user.secretary?
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
