# frozen_string_literal: true

class CalendarPolicy < ApplicationPolicy
  def index?
    user.root? || user.neighbourhood_admin? || user.partner_admin?
  end

  def create?
    index?
  end

  def new?
    index?
  end

  def edit?
    update?
  end

  def update?
    return true if user.root?
    return true if scope.map(&:id).include? record.id
  end

  def import?
    index?
  end

  def select_page?
    index?
  end

  def destroy?
    index?
  end

  class Scope < Scope
    def resolve
      return scope.all if user.root?
      return scope.none if !user.partner_admin? && !user.neighbourhood_admin? && !user.partnership_admin?

      if user.partnership_admin?
        user_partnership_tag_ids = user.tags.map(&:id)
        partnership_calendars =
          Calendar.left_joins(partner: %i[address service_areas partnerships])
                  .where(
                    'calendars.partner_id IN (:partner_ids) OR
                      ( partner_tags.tag_id IN (:tags) AND
                       (addresses.neighbourhood_id in (:neighbourhood_ids) OR
                      service_areas.neighbourhood_id in (:neighbourhood_ids)))',
                    neighbourhood_ids: user.owned_neighbourhood_ids,
                    partner_ids: user.partner_ids,
                    tags: user_partnership_tag_ids
                  )
                  .distinct
      else
        neighbourhood_calendars =
          Calendar.left_joins(partner: %i[address service_areas])
                  .where(
                    '(addresses.neighbourhood_id in (:neighbourhood_ids) OR '\
                    'service_areas.neighbourhood_id in (:neighbourhood_ids) OR '\
                    'calendars.partner_id IN (:partner_ids))',
                    neighbourhood_ids: user.owned_neighbourhood_ids,
                    partner_ids: user.partner_ids
                  )
                  .distinct
      end
    end
  end
end
