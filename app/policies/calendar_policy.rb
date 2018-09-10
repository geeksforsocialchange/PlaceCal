# frozen_string_literal: true

class CalendarPolicy < ApplicationPolicy

  def index?
    %w[root partner_admin].include? user&.role
  end

  def create?
    index?
  end

  def new?
    index?
  end

  def edit?
    return true if user&.role&.root?

    user&.role&.partner_admin? &&
      user.partner_ids.include?(record.partner_id)
  end

  def update?
    edit?
  end

  def import?
    user.role.root?
  end

  def select_page?
    index?
  end

  class Scope < Scope
    def resolve
      if user&.role&.root?
        scope.all
      else
        scope.joins(partner: :users).where(partners_users: { user_id: user.id })
      end
    end
  end
end
