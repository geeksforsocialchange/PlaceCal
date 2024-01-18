# frozen_string_literal: true

class TagPolicy < ApplicationPolicy
  def index?
    user.root?
  end

  def new?
    user.root?
  end

  def create?
    user.root?
  end

  def edit?
    user.root?
  end

  def update?
    user.root?
  end

  def destroy?
    user.root?
  end

  def permitted_attributes
    return unless user.root?

    fields = %i[name slug description system_tag]
    fields << :type if @record.instance_of?(Tag)
    fields.push(partner_ids: [], user_ids: [])
  end

  def disabled_fields
    if user.root?
      %i[]
    elsif user.tag_admin? && user.tags.include?(@record)
      %i[system_tag users user_ids]
    elsif user.tag_admin? || user.partner_admin?
      %i[name slug description users user_ids system_tag]
    else # Should never be hit, but it's useful as a guard
      %i[name slug description users partner_ids user_ids system_tag]
    end
  end

  class Scope < Scope
    def resolve
      Tag.users_tags(user)
    end
  end
end
