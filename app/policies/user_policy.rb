class UserPolicy < ApplicationPolicy
  attr_reader :current_user, :scope

  def initialize(user, record)
    @user = user
    @record = record
  end

  def check_role?
    @user.role? && @user.role.secretary?
  end
end
