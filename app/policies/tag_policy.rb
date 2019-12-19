# frozen_string_literal: true

class TagPolicy < ApplicationPolicy
  def index?
    user.root? || user.tag_admin?
  end

  def new?
    index?
  end

  def create?
    index?
  end

  def edit?
    index?
  end

  def update?
    index?
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
