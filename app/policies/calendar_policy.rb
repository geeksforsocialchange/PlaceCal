# frozen_string_literal: true

class CalendarPolicy < ApplicationPolicy
  def index?
    user.root? || user.neighbourhood_admin? || user.partner_admin?
  end

  def create?
    index? && partners_in_scope?
  end

  def new?
    index?
  end

  def edit?
    update?
  end

  def update?
    return true if user.root?

    scope.map(&:id).include?(record.id) && partners_in_scope?
  end

  def import?
    update?
  end

  def destroy?
    update?
  end

  private

  # A changed organiser or default location must be a partner the user manages; unchanged ones are left alone.
  def partners_in_scope?
    return true if user.root? || !record.is_a?(Calendar)

    ids = %i[organiser_id place_id].filter_map { |attr| record[attr] if record.will_save_change_to_attribute?(attr) }
    (ids - Pundit.policy_scope!(user, Partner).where(id: ids).pluck(:id)).empty?
  end

  class Scope < Scope
    def resolve
      return scope.all if user.root?
      return scope.none if !user.partner_admin? && !user.neighbourhood_admin? && !user.partnership_admin?

      if user.partnership_admin?
        user_partnership_tag_ids = user.tags.map(&:id)
        Calendar.left_joins(organiser: %i[address service_areas partnerships])
                .where(
                  'calendars.organiser_id IN (:partner_ids) OR
                      ( partner_tags.tag_id IN (:tags) AND
                       (addresses.neighbourhood_id in (:neighbourhood_ids) OR
                      service_areas.neighbourhood_id in (:neighbourhood_ids)))',
                  neighbourhood_ids: user.owned_neighbourhood_ids,
                  partner_ids: user.partner_ids,
                  tags: user_partnership_tag_ids
                )
                .distinct
      else
        Calendar.left_joins(organiser: %i[address service_areas])
                .where(
                  '(addresses.neighbourhood_id in (:neighbourhood_ids) OR '\
                  'service_areas.neighbourhood_id in (:neighbourhood_ids) OR '\
                  'calendars.organiser_id IN (:partner_ids))',
                  neighbourhood_ids: user.owned_neighbourhood_ids,
                  partner_ids: user.partner_ids
                )
                .distinct
      end
    end
  end
end
