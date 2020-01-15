# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  attr_reader :current_user, :scope

  def initialize(user, record)
    @user = user
    @record = record
  end

  def profile?
    user.id == record.id
  end

  def update_profile?
    profile?
  end

  def index?
    user.root? || user.neighbourhood_admin?
  end

  def create?
    index?
  end

  def new?
    index?
  end

  def update?
    index?
  end

  def edit?
    index?
  end

  def destroy?
    user.root?
  end

  def permitted_attributes
    [ :first_name, :last_name, :email, :phone, :role, :avatar, :facebook_app_id, :facebook_app_secret, tag_ids: [], partner_ids: [], neighbourhood_ids: [] ]
  end

  def permitted_attributes_for_update
    if user.root?
      permitted_attributes
    elsif user.neighbourhood_admin?
      [ neighbourhood_ids: [] ]
    end
  end
end
