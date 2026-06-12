# frozen_string_literal: true

class PartnershipBroadcastPolicy < ApplicationPolicy
  def index?
    manage?
  end

  def new?
    manage?
  end

  def create?
    manage?
  end

  private

  # Root and national admins, plus the admins of this partnership
  def manage?
    return true if user.root? || user.national_admin?

    user.partnerships.exists?(record.partnership_id)
  end

  class Scope < Scope
    def resolve
      return scope.all if user.root? || user.national_admin?

      scope.where(partnership_id: user.partnerships.select(:id))
    end
  end
end
