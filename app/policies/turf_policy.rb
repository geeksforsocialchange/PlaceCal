class TurfPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.role.root?
        scope.all
      else
        user.turfs
      end
    end
  end
end
