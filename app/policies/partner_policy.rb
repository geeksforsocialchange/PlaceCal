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
    return true if user.admin_for_partner?(record.id)
    return true if user.partnership_admin_for_partner?(record.id)
    return true if user.neighbourhood_admin_for_partner?(record.id)

    false
  end

  def edit?
    update?
  end

  def destroy?
    return true if user.root?
    return true if user.admin_for_partner?(record.id)
    return true if user.only_partnership_admin_for_partner?(record.id)
    return true if user.only_neighbourhood_admin_for_partner?(record.id)
  end

  def clear_address?
    index?
  end

  def setup?
    create?
  end

  def permitted_attributes
    attrs = [:name, :image, :summary, :description, :accessibility_info,
             :public_name, :public_email, :public_phone,
             :partner_name, :partner_email, :partner_phone,
             :address_id, :url, :facebook_link, :twitter_handle,
             :opening_times,
             { calendars_attributes: %i[id name source strategy place_id partner_id _destroy],
               address_attributes: %i[id street_address street_address2 street_address3 city postcode],
               service_areas_attributes: %i[id neighbourhood_id _destroy],
               tag_ids: [] }]

    attrs << :slug if user.root?
    attrs
  end

  class Scope < Scope
    def resolve
      if user.root?
        scope.all

      elsif user.partnership_admin?
        user_neighbourhood_ids = user.owned_neighbourhood_ids
        user_partnership_tag_ids = user.tags.map(&:id)

        # If the user is a partner admin,
        # or if they manage their partnership tag AND they neighbourhood admin for them
        clause = <<-SQL.squish
        partners_users.user_id = ? OR
          (
          partner_tags.tag_id IN (?) AND
            (
              addresses.neighbourhood_id IN (?)
              OR service_areas.neighbourhood_id IN (?)
            )
          )
        SQL

        scope
          .left_outer_joins(:users, :tags, :address, :service_areas)
          .where(
            clause,
            user.id,
            user_partnership_tag_ids,
            user_neighbourhood_ids,
            user_neighbourhood_ids
          ).distinct

      else
        user_neighbourhood_ids = user.owned_neighbourhood_ids

        # If the user is a partner admin,
        # or if they neighbourhood admin for them
        clause = <<-SQL.squish
          partners_users.user_id = ?
            OR addresses.neighbourhood_id IN (?)
            OR service_areas.neighbourhood_id IN (?)
        SQL

        scope
          .left_outer_joins(:users, :address, :service_areas)
          .where(clause, user.id, user_neighbourhood_ids, user_neighbourhood_ids)
          .distinct
      end
    end
  end
end
