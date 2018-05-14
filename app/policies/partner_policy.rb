class PartnerPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    user&.role&.root? || user&.role&.turf_admin?
  end

  def new?
    create?
  end

  def update?
    user.role.present?
  end

  def edit?
    update?
  end

  def destroy?
    update?
  end

  class Scope < Scope
    def resolve
      if user&.role&.root?
        scope.all
      elsif user&.role&.partner_admin? || user&.role&.turf_admin?
        scope.joins(:turfs).where(turfs: { id: user.turfs }).distinct
      end
    end
  end
end
