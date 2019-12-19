# frozen_string_literal: true

# app/policies/neighbourhood_policy.rb
class NeighbourhoodPolicy < ApplicationPolicy
  # We don't really want anyone looking at this it's a bit abstract
  def index?
    user.root?
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
      elsif user.neighbourhood_admin?
        user.neighbourhoods
      else
        scope.none
      end
    end
  end
end
