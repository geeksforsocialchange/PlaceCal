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

  class Scope < Scope
    def resolve
      Tag.users_tags(user)
    end
  end
end
