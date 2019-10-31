# frozen_string_literal: true

class PartnerPolicy < ApplicationPolicy
  def index?
    user&.role.present? && !user.role.citizen?
  end

  def create?
    %w[root turf_admin].include? user&.role
  end

  def new?
    create?
  end

  def update?
    return false if user.role.blank?
    return true if user.role.root?

    if user.role.turf_admin?
      record.turfs.where(turfs: { id: user.turf_ids }).exists?
    elsif user.role.partner_admin?
      user.partner_ids.include?(record.id)
    end
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
      elsif user&.role&.turf_admin?
        scope.joins(:turfs).where(turfs: { id: user.turfs }).distinct
      elsif user&.role&.partner_admin?
        scope.joins(:users).where(partners_users: { user_id: user.id })
      else
        scope.none
      end
    end
  end
end
