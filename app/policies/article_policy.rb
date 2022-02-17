# frozen_string_literal: true

class ArticlePolicy < ApplicationPolicy
  def index?
    user.root? or user.editor?
  end

  def edit?
    user.root? or user.editor?
  end

  def new?
    user.root? or user.editor?
  end

  def create?
    user.root? or user.editor?
  end

  def destroy?
    user.root? or user.editor?
  end

  class Scope < Scope
    def resolve
      return scope.all if user.root? || user.editor?
    end
  end
end
