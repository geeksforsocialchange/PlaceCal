class TurfPolicy < ApplicationPolicy

  def index?
    user.role.present? && (user.role.root? || user.role.turf_admin?)
  end

  def new?
    user.role.present? && user.role.root?
  end

  def create?
    new?
  end

  def edit?
    new?
  end

  def update?
    new?
  end

  class Scope < Scope
    def resolve
      if user&.role&.root?
        scope.all
      else
        user.turfs
      end
    end
  end
end
