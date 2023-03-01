# frozen_string_literal: true

class TagPolicy < ApplicationPolicy
  def index?
    user.root? || user.partner_admin? || user.tag_admin?
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
    if user.root?
      fields = %i[name slug description system_tag]
      fields << :type if @record.instance_of?(Tag)
      fields.push(partner_ids: [], user_ids: [])

    elsif user.tag_admin? && user.tags.include?(@record)
      %i[].push(partner_ids: [])
    else
      %i[]
    end
  end

  def disabled_fields
    if user.root?
      %i[]
    elsif user.tag_admin?
      %i[name slug description users user_ids system_tag]
    else # Should never be hit, but it's useful as a guard
      %i[name slug description users partner_ids user_ids system_tag]
    end
  end

  class Scope < Scope
    def resolve
      if user.root?
        scope.all
      else
        Tag.users_tags(user)
      end
    end
  end
end
