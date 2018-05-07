class SitePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.role&.root?
        scope.all
      end
    end
  end
end
