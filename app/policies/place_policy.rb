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
      elsif user&.role&.turf_admin?
        scope.joins(:turfs).where(turfs: { id: user.turfs }).distinct
      elsif user&.role&.partner_admin?
        scope.joins(partners: :users).where(partners_users: {user_id: user.id}) 
      end
    end
  end
end
