# frozen_string_literal: true

class ArticlePolicy < ApplicationPolicy
  # The permissions for /index, which are basically universal across all actions someone can take
  # This is just a litmus test and we flesh out the list of Articles someone can see in Scope#resolve,
  # and the list of fields they can edit for each Article in #permitted_attributes/#disabled_fields
  #
  # @return [Boolean]
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

  # A list of attributes that someone is allowed to pass via POST/PATCH
  #
  # We do a broad-spectrum "allow" here. Because:
  # - We do not expect someone manually POST/PATCH these parameters
  # - Removing them from this list would mean the form doesn't show them.
  #
  # So instead, we rely on disabled_fields so the user can look, but not touch
  #
  # @returns [Array<String>] A list of URL Parameters
  def permitted_attributes
    [:title, :author_id, :body, :published_at, :is_draft, :article_image,
     { partner_ids: [] }, { tag_ids: [] }]
  end

  # Form fields that the user can not interact with
  #
  # @return [Array<String>] A list of URL Parameters the user cannot edit
  def disabled_fields
    # Partner admins can edit the assigned partners for the article
    if user.root? || user.editor?
      %i[]
    elsif user.partner_admin? || user.neighbourhood_admin?
      %i[author_id]
    else # Should never be hit, but it's useful as a guard
      %i[title author_id body published_at is_draft article_image partner_ids]
    end
  end

  class Scope < Scope
    # Resolves the list of Articles the user can see
    # In this case, we want to ensure that:
    # - Root / Editor roles can see everything
    # - Partner Admin and Neighbourhood Admin roles can see Articles from
    #   their neighbourhoods/service areas
    # @return [ActiveRecord::Relation<Article>] A list of Articles to show in /index
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

  # Does the current User have Partners in their Neighbourhoods?
  # @return [ActiveRecord::Relation<Article>] A list of Partners
  def owned_neighbourhoods_have_partners?
    # We can make this less shallow, but it's not important since scoping rules have the deeper stuff anyway
    Partner.from_neighbourhoods_and_service_areas(user.owned_neighbourhood_ids).count.positive?
  end
end
