# frozen_string_literal: true

class TagPolicy < ApplicationPolicy
  def index?
    user.root? || user.tag_admin?
  end

  def new?
    user.root?
  end

  def create?
    user.root?
  end

  def edit?
    user.root?
  end

  def update?
    user.root?
  end

  def destroy?
    user.root?
  end

  class Scope < Scope
    def resolve
      if user.root?
        scope.all
      else
        user.tags
      end
    end
  end
end
