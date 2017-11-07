class CalendarPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      @user.role.admin? ? scope : scope.joins(:partner).joins("INNER JOIN partners_users ON partners_users.partner_id = partners.id").where(partners_users: { user_id: @user.id })
    end
  end
end
