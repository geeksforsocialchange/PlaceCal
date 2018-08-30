# frozen_string_literal: true

class CalendarPolicy < ApplicationPolicy
  def create?
    %w[root partner_admin].include? user&.role
  end

  def index?
    create?
  end

  def new?
    create?
  end

  def edit?
    create?
  end

  def update?
    create?
  end

  def import?
    user.role.root?
  end

  def select_page?
    true
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
