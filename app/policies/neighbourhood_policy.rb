# frozen_string_literal: true

# app/policies/neighbourhood_policy.rb
class NeighbourhoodPolicy < ApplicationPolicy
  def index?
    user.root? || user.neighbourhood_admin?
  end

  def new?
    user.root?
  end

  def create?
    user.root?
  end

  def edit?
    user.root? || user.neighbourhood_admin?
  end

  def update?
    user.root? || user.neighbourhood_admin?
  end

  def destroy?
    user.root?
  end

  def set_users?
    user.root?
  end

  def permitted_attributes
    if user.root?
      %i[ name name_abbr ward district county region
          WD19CD WD19NM LAD19CD LAD19NM CTY19CD CTY19NM RGN19CD RGN19NM
        ].push(user_ids: [])
    else
      %i[name ward district county region]
    end
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
