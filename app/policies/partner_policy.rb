class PartnerPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    !user.role.partner_admin?
  end

  def new?
    create?
  end

  def update?
    index?
  end

  def edit?
    index?
  end

  # def destroy?
  #   index?
  # end

  class Scope < Scope
    def resolve
      if user&.role&.root?
        scope.all
      else
        scope.joins(:turfs).where(turfs: { id: user.turfs }).distinct
      end
    end
  end
end
