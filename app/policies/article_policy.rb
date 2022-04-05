# frozen_string_literal: true

class ArticlePolicy < ApplicationPolicy
  def index?
    return true if user.root? || user.editor?
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
    [:title, :author_id, :body, :published_at, :is_draft, :article_header, partner_ids: []]
  end

  def disabled_fields
    # Partner admins can edit the assigned partners for the article
    if user.root?
      %i[]
    elsif user.editor? || user.partner_admin? || user.neighbourhood_admin?
      %i[author_id]
    else # Should never be hit, but it's useful as a guard
      %i[title author_id body published_at is_draft article_header partner_ids]
    end
  end

  class Scope < Scope
    def resolve
      return scope.all if user.root? || user.editor?

      return scope.none unless user.neighbourhood_admin? || user.partner_admin?

      neighbourhood_ids = user.owned_neighbourhood_ids
      neighbourhood_partners = Partner.from_neighbourhoods_and_service_areas(neighbourhood_ids)
      partner_ids = user.partners + neighbourhood_partners.map(&:id)

      Article.joins(:article_partners).where('article_partners.partner_id' => partner_ids)
    end
  end

  private

  def owned_neighbourhoods_have_partners?
    # We can make this less shallow, but it's not important since scoping rules have the deeper stuff anyway
    Partner.from_neighbourhoods_and_service_areas(user.owned_neighbourhood_ids).count.positive?
  end
end
