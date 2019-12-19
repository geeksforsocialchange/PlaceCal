# frozen_string_literal: true

class PartnerPolicy < ApplicationPolicy
  def index?
    user&.role.present? && !user.role.citizen?
  end

  def create?
    %w[root tag_admin].include? user&.role
  end

  def new?
    create?
  end

  def update?
    return false if user.role.blank?
    return true if user.role.root?

    if user.role.tag_admin?
      record.tags.where(tags: { id: user.tag_ids }).exists?
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
      elsif user&.role&.tag_admin?
        scope.joins(:tags).where(tags: { id: user.tags }).distinct
      elsif user&.role&.partner_admin?
        scope.joins(:users).where(partners_users: { user_id: user.id })
      else
        scope.none
      end
    end
  end
end
