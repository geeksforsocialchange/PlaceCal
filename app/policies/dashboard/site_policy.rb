# frozen_string_literal: true

class Dashboard::SitePolicy < SitePolicy
  class Scope < Scope
    def resolve
      if user.site_admin?
        scope.where(site_admin: user)
      elsif user.root?
        scope.all
      else
        scope.none
      end
    end
  end
end
