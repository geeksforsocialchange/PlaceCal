class PlacePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    ['root', 'turf_admin'].include? user&.role
  end

  def new?
    create?
  end

  def update?
    user.role?
  end

  def edit?
    update?
  end

  def destroy?
    create?
  end

  class Scope < Scope
    def resolve
      if user&.role&.root?
        scope.all
      elsif ['partner_admin', 'turf_admin'].include? user&.role
        scope.joins(:turfs).where(turfs: { id: user.turfs }).distinct
      end
    end
  end
end
