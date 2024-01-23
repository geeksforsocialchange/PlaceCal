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
    user.root? || user.neighbourhood_admin? || user.partnership_admin?
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
    attrs = [
      :first_name,
      :last_name,
      :email,
      :phone,
      :avatar,
      { partner_ids: [] }
    ]
    root_attrs = [
      :role,
      { tag_ids: [],
        neighbourhood_ids: [] }
    ]

    user.root? ? attrs + root_attrs : attrs
  end

  def all_user_partners_in_admin_neighbourhood?(user, admin)
    (
      (
        user.partners.map { |p| p.address&.neighbourhood_id } +
        user.partners.flat_map { |p| p.service_area_neighbourhoods.pluck(:id) }
      ).uniq - admin.owned_neighbourhood_ids
    ).empty?
  end

  def permitted_attributes_for_update
    if user.root?
      permitted_attributes
    elsif user.neighbourhood_admin?
      [partner_ids: []]
    end
  end

  def permitted_attributes_for_create
    attrs = [
      :first_name,
      :last_name,
      :email,
      :phone,
      :avatar,
      { partner_ids: [] }
    ]
    root_attrs = [
      :role,
      { tag_ids: [],
        neighbourhood_ids: [] }
    ]

    user.root? ? attrs + root_attrs : attrs
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

  class Scope < Scope
    def resolve
      if user.root?
        scope.all

      elsif user.partnership_admin?
        user_neighbourhood_ids = user.owned_neighbourhood_ids
        user_partnership_tag_ids = user.tags.map(&:id)

        scope
          .left_joins(partners: %i[address service_areas partner_tags])
          .where(
            'partner_tags.tag_id IN (:tags) AND
              (
                addresses.neighbourhood_id IN (:ids) OR
                service_areas.neighbourhood_id IN (:ids)
              )',
            ids: user_neighbourhood_ids,
            tags: user_partnership_tag_ids
          ).distinct

      else
        user_neighbourhood_ids = user.owned_neighbourhood_ids

        scope
          .left_joins(partners: %i[address service_areas])
          .where(
            'addresses.neighbourhood_id IN (:ids) OR
            service_areas.neighbourhood_id IN (:ids)',
            ids: user_neighbourhood_ids
          ).distinct
      end
    end
  end
end
