# frozen_string_literal: true

# policy set to allow root only while developing article functionality

class ArticlePolicy < ApplicationPolicy
  def index?
    user.root?
  end

  def edit?
    user.root?
  end

  def new?
    user.root?
  end

  def create?
    user.root?
  end

  def destroy?
    user.root?
  end

  class Scope < Scope
    def resolve
      return scope.all if user.root?
    end
  end
end
