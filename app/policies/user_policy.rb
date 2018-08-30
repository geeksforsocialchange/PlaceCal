# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  attr_reader :current_user, :scope

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user&.role&.root?
  end

  def update?
    index?
  end

  def assign_turf?
    index?
  end

  def edit?
    index?
  end

  def destroy?
    index?
  end
end
