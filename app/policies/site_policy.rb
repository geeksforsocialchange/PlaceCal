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
