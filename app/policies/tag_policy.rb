# frozen_string_literal: true

class TagPolicy < ApplicationPolicy
  def index?
    user.secretary? || user.tag_admin?
  end

  def new?
    user.root?
  end

  def create?
    new?
  end

  def edit?
    new?
  end

  def update?
    new?
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
