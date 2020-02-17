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
    attrs = [ :first_name,
              :last_name,
              :email,
              :phone,
              :avatar,
              partner_ids: []
            ]
    if user.root?
      attrs << :role
      attrs << :facebook_app_id
      attrs << :facebook_app_secret
      attrs << { tag_ids: [] }
      attrs << { neighbourhood_ids: [] }
    else
      attrs
    end
  end

  def permitted_attributes_for_update
    if user.root?
      permitted_attributes
    elsif user.neighbourhood_admin?
      [ partner_ids: [] ]
    end
  end
end
