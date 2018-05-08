class SitePolicy < ApplicationPolicy

  def index?
    true
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
      end
    end
  end
end
