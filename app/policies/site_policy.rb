# frozen_string_literal: true

class SitePolicy < ApplicationPolicy
  def index?
    user.root? || user.site_admin?
  end

  def new?
    user.root?
  end

  def create?
    user.root?
  end

  def edit?
    user.root? || record.site_admin == user
  end

  def show?
    user.root?
  end

  def update?
    user.root? || record.site_admin == user
  end

  def destroy?
    user.root?
  end

  # An extension theme is not a colour scheme: it swaps in an engine's views,
  # components and copy, and it only exists on installations whose operator
  # has added that gem. Site admins choose among the themes core ships; only
  # root moves a site onto (or off) an extension theme.
  #
  # @return [Array<PlaceCal::Theme>]
  def permitted_themes
    themes = user.root? ? PlaceCal::Extensions.themes : PlaceCal::Extensions.themes.select(&:core?)
    # The site's current theme stays selectable whoever is editing, so a site
    # admin saving the form cannot silently move an extension-themed site onto
    # a core theme.
    themes | [PlaceCal::Extensions.find_theme(current_theme_name)].compact
  end

  # @param name [String, nil] a submitted theme name
  # @return [Boolean] whether this user may set the site to it
  def permitted_theme?(name)
    name = name.to_s
    return true if name.blank? || name == current_theme_name

    permitted_themes.any? { |theme| theme.name == name }
  end

  def permitted_attributes
    attrs = %i[id name place_name logo footer_logo is_published tagline description
               badge_zoom_level hero_image hero_image_credit hero_alttext hero_text theme
               contact_email]
            .push(sites_neighbourhoods_attributes: %i[_destroy id neighbourhood_id relation_type],
                  sites_neighbourhood_attributes: %i[_destroy id neighbourhood_id relation_type])

    root_attrs = %i[slug url site_admin_id tags sites_neighbourhoods]
                 .push(tag_ids: [])

    return root_attrs + attrs if user.root?

    attrs
  end

  private

  # The theme the record is stored with, ignoring anything just assigned from
  # the form, so a submitted extension theme cannot authorise itself. "" for a
  # new site and for the Site class (Pundit's headless create check).
  #
  # @return [String]
  def current_theme_name
    record.respond_to?(:theme_was) ? record.theme_was.to_s : ''
  end

  class Scope < Scope
    def resolve
      if user.root?
        scope.all
      elsif user.site_admin?
        scope.where(site_admin: user)
      else
        scope.none
      end
    end
  end
end
