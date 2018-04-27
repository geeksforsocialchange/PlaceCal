class UserPolicy < ApplicationPolicy
  attr_reader :current_user, :scope

  def initialize(user, record)
    @user = user
    @record = record
  end

  def check_root_role?
    @user.role? && @user.role.root?
  end

  def allow_edit_turf?
    @user.role? && @user.role.root?
  end

  def check_secretary_role?
    @user.role? && @user.role.secretary?
  end

  def check_role?
    @user.role? && (@user.role.secretary? || @user.role.root?)
  end
end
