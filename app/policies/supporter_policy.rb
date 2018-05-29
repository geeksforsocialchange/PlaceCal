# frozen_string_literal: true

# app/policies/supporter_policy.rb
class SupporterPolicy < ApplicationPolicy
  def index?
    user&.role&.root?
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
end
