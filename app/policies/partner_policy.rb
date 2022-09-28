# frozen_string_literal: true

class PartnerPolicy < ApplicationPolicy
  def index?
    user.root? || user.neighbourhood_admin? || user.partner_admin?
  end

  def show?
    update?
  end

  def create?
    user.root? || user.neighbourhood_admin?
  end

  def new?
    create?
  end

  def update?
    return true if user.root?

    return true if user.can_alter_neighbourhood_by_id?(record.neighbourhood_id)
    return true if user.can_alter_partner_by_id?(record.id)

    false
  end

  def edit?
    update?
  end

  def destroy?
    return true if user.root?
    return false unless user.neighbourhood_admin?

    user.owned_neighbourhood_ids.include?(record.neighbourhood_id)
  end

  def setup?
    create?
  end

  def permitted_attributes
    attrs = [
      :name,
      :image,
      :summary,
      :description,
      :accessibility_info,
      :public_name,
      :public_email,
      :public_phone,
      :partner_name,
      :partner_email,
      :partner_phone,
      :address_id,
      :url,
      :facebook_link,
      :twitter_handle,
      :opening_times,
      calendars_attributes: %i[
        id
        name
        source
        strategy
        place_id
        partner_id
        _destroy
      ],
      address_attributes: %i[
        id
        street_address
        street_address2
        street_address3
        city
        postcode
      ],
      service_areas_attributes: %i[id neighbourhood_id _destroy],
      tag_ids: []
    ]

    attrs << :slug if user.root?
    attrs
  end

  class Scope < Scope
    def resolve
      if user.root?
        scope.all
      else
        user_neighbourhood_ids = user.owned_neighbourhood_ids

        clause = <<-SQL
          partners_users.user_id = ?
            OR addresses.neighbourhood_id IN (?)
            OR service_areas.neighbourhood_id IN (?)
        SQL

        scope
          .left_outer_joins(:users, :address, :service_areas)
          .where(
            clause,
            user.id,
            user_neighbourhood_ids,
            user_neighbourhood_ids
          )
          .distinct
      end
    end
  end
end
