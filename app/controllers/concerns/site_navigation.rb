# frozen_string_literal: true

# Public navigation for the nationwide directory and for a local site.
#
# A site's nav is *derived*, never configured (#3368 D6): it follows from the
# site's own data (does it have news? in-nav pages? an enquiries address?), so
# there is no nav editor to keep in sync and a new page appears in the nav the
# moment it is published.
module SiteNavigation
  extend ActiveSupport::Concern

  private

  def directory_navigation
    [
      [t('navigation.directory.home'), root_path],
      [t('navigation.directory.partners'), partners_path],
      [t('navigation.directory.partnerships'), partnerships_path],
      [t('navigation.directory.events'), events_path]
    ]
  end

  # Home, Events, Partners, then News (when the site has published articles),
  # the site's in-nav Pages, and a Join link when the site takes its own
  # enquiries (D13).
  def sub_site_navigation
    core_navigation + news_navigation + page_navigation + join_navigation
  end

  # Region is sticky via links, not state (D20): when a region is selected only
  # these three links carry it.
  def core_navigation
    region_params = current_region ? { region: current_region.slug } : {}
    [
      [t('navigation.site.home'), root_path(region_params)],
      [t('navigation.site.events'), events_path(region_params)],
      [t('navigation.site.partners'), partners_path(region_params)]
    ]
  end

  def news_navigation
    return [] unless current_site&.news_article_count&.positive?

    [[t('navigation.site.news'), news_index_path]]
  end

  def page_navigation
    return [] if current_site.nil?

    current_site.pages.in_nav.map { |page| [page.title, "/#{page.slug}"] }
  end

  def join_navigation
    return [] if current_site&.contact_email.blank?
    return [] if current_site.theme_definition&.nav_join? == false

    [[t('navigation.site.join'), get_in_touch_path]]
  end
end
