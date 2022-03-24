# frozen_string_literal: true

class ArticlePolicy < ApplicationPolicy
  def index?
    user.root? or user.editor? or user.neighbourhood_admin? or user.partner_admin?
    return true if user.root? or user.editor?
    return true if user.partner_admin? && user.partners.count.positive?

    # True if neighbourhood admin oversees any partners
    return true if user.neighbourhood_admin? && owned_neighbourhoods_have_partners?
  end

  def show?
    index?
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
    update?
  end

  def destroy?
    update?
  end

  def permitted_attributes
    %i[title body published_at is_draft].push(partner_ids: [])
  end

  def disabled_fields
    # Partner admins can edit the assigned partners for the article
    if user.root? || user.editor? || user.partner_admin? || user.neighbourhood_admin?
      %i[]
    else # Should never be hit, but it's useful as a guard
      %i[title body published_at is_draft partner_ids]
    end
  end

  class Scope < Scope
    def resolve
      return scope.all if user.root? || user.editor?

      return scope.none unless user.neighbourhood_admin? || user.partner_admin?

      neighbourhood_ids = user.owned_neighbourhood_ids
      neighbourhood_partners = Partner.from_neighbourhoods_and_service_areas(neighbourhood_ids)
      partner_ids = user.partners + neighbourhood_partners.map(&:id)

      # luckily this is a single sql line, but this whole thing could probably be condensed a bit better
      # ew ew ew ew
      Article.where(id: ArticlePartner.where(partner_id: partner_ids).map(&:article_id))
    end
  end

  private

  def owned_neighbourhoods_have_partners?
    # We can make this less shallow, but it's not important since scoping rules have the deeper stuff anyway
    Partner.from_neighbourhoods_and_service_areas(user.owned_neighbourhood_ids).count.positive?
  end
end
