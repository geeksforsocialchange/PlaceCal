# frozen_string_literal: true

class TagPolicy < ApplicationPolicy
  def index?
    %w[root tag_admin].include? user&.role
  end

  def new?
    user&.role&.root?
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
      if user&.role&.root?
        scope.all
      else
        user.tags
      end
    end
  end
end
