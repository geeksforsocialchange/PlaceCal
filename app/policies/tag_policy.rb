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
    user.root? || user.partner_admin? || user.tag_admin?
  end

  def update?
    return true if user.root?

    # system tags can only be edited by root
    return false if @record.system_tag

    # NB: We literally can't filter by partners added because otherwise itll wipe existing partners
    #
    # If the user is a partner admin and the tag is generally available for use
    # Functionally, anyone who is a tag admin will be a partner admin, HOWEVER, testing code requi-
    # Also, it probably doesn't hurt to be strict.
    return true if user.partner_admin? || user.tag_admin?

    false
  end

  def destroy?
    user.root?
  end

  def permitted_attributes
    if user.root?
      fields = %i[name slug description system_tag]
      fields << :type if @record.instance_of?(Tag)
      fields.push(partner_ids: [], user_ids: [])
    elsif user.tags.include?(@record)
      fields = %i[name slug description]
      fields.push(partner_ids: [])
    elsif user.partner_admin?
      %i[].push(partner_ids: [])
    else
      %i[]
    end
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
