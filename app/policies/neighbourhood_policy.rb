# frozen_string_literal: true

# app/policies/neighbourhood_policy.rb
class NeighbourhoodPolicy < ApplicationPolicy
  def index?
    user.root? or user.neighbourhood_admin?
  end

  def new?
    user.root?
  end

  def create?
    user.root?
  end

  def edit?
    user.root? or user.neighbourhood_admin?
  end

  def update?
    user.root? or user.neighbourhood_admin?
  end

  def destroy?
    user.root?
  end

  def set_users?
    user.root?
  end

  def permitted_attributes
    if user.root?
      %i[name name_abbr unit unit_code_key unit_code_value unit_name release_date].push(user_ids: [])
    else
      %i[name name_abbr]
    end
  end

  class Scope < Scope
    def resolve
      if user.root?
        scope.all
      elsif user.neighbourhood_admin?
        scope.where(id: user.owned_neighbourhood_ids).distinct
      else
        scope.none
      end
    end
  end
end
