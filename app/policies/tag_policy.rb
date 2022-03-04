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

    # If the user is a tag admin and has been assigned this tag
    return true if user.tag_admin? && user.tags.include?(@record)

    # NB: We literally can't filter by partners added because otherwise itll wipe existing partners
    #
    # If the user is a partner admin and the tag is generally available for use
    # Functionally, anyone who is a tag admin will be a partner admin, HOWEVER, testing code requi-
    # Also, it probably doesn't hurt to be strict.
    return true if (user.partner_admin? || user.tag_admin?) && @record.edit_permission == :all

    false
  end

  def destroy?
    user.root?
  end

  def permitted_attributes
    if user.root?
      %i[name slug description edit_permission]
        .push(partner_ids: [], user_ids: [])
    elsif user.tag_admin? && user.tags.include?(@record)
      %i[].push(partner_ids: [])
    elsif @record.edit_permission == :all
      %i[].push(partner_ids: [])
    else
      %i[]
    end
  end

  def disabled_fields
    if user.root?
      %i[]
    elsif user.tag_admin? || @record.edit_permission == :all
      %i[name slug description users edit_permission user_ids]
    else # Should never be hit, but it's useful as a guard
      %i[name slug description users edit_permission partner_ids user_ids]
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
