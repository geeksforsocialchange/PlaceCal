# frozen_string_literal: true

# Who may manage a Site's static content pages (#3368, D5).
#
# Root and editor users manage every page. A site admin manages the pages of
# the sites they administer, and nothing else.
class PagePolicy < ApplicationPolicy
  def index?
    user.root? || user.editor? || user.site_admin?
  end

  def show?
    index?
  end

  def new?
    create?
  end

  def create?
    return true if user.root? || user.editor?

    # A new Page may not have a site yet (the form assigns one); allow any
    # site admin to reach the form, and check ownership on the saved record.
    user.site_admin? && (record_site.nil? || administers_record_site?)
  end

  def update?
    return true if user.root? || user.editor?

    administers_record_site?
  end

  def edit?
    update?
  end

  def destroy?
    update?
  end

  # Site admins pick from their own sites in the form, so site_id is only
  # writable by root/editor.
  #
  # @return [Array<Symbol>] URL parameters the user may submit
  def permitted_attributes
    attrs = %i[title slug body position show_in_nav is_published]
    return attrs + %i[site_id] if user.root? || user.editor?

    attrs
  end

  class Scope < Scope
    # @return [ActiveRecord::Relation<Page>]
    def resolve
      return scope.all if user.root? || user.editor?
      return scope.where(site: Site.where(site_admin: user)) if user.site_admin?

      scope.none
    end
  end

  private

  # The record can be a Page, a relation (index) or the Page class itself.
  def record_site
    record.respond_to?(:site) ? record.site : nil
  end

  def administers_record_site?
    site = record_site
    site.present? && site.site_admin == user
  end
end
