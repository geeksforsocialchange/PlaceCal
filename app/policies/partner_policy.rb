class PartnerPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.role.root?
        scope.all
      else
        scope.joins(:turfs).where(turfs: { id: user.turfs }).distinct
      end
    end
  end
end