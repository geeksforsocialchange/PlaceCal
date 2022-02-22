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
      attrs << { tag_ids: [] }
      attrs << { neighbourhood_ids: [] }
      attrs << :facebook_app_id
      attrs << :facebook_app_secret
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

  def permitted_attributes_for_create
    attrs = %i[
      first_name
      last_name
      email
      phone
      avatar
      partner_ids
    ]
    root_attrs = %i[
      role
      tag_ids
      neighbourhood_ids
      facebook_app_id
      facebook_app_secret
    ]

    return attrs + root_attrs if user.root?

    attrs
  end

  def disabled_attributes_for_update
    attrs = %i[
      first_name
      last_name
      email
      phone
      avatar
    ]

    return [] if user.root?

    attrs
  end
end
