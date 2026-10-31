# frozen_string_literal: true

# @display padding false
class Shared::NavigationPreview < Lookbook::Preview
  # @label Directory (no site)
  def directory
    render Components::Shared::Navigation.new(
      navigation: PreviewSupport.sample_navigation,
      site: nil
    )
  end

  # @label Site with a theme call to action
  # @notes A theme that sets nav_cta and menu_label, as Trans Dimension does with its Donate link.
  def site_with_theme_cta
    Current.theme = PlaceCal::Theme.new(:preview).tap do |theme|
      theme.nav_cta "navigation.site.home", "https://example.org/donate"
      theme.menu_label true
    end
    render Components::Shared::Navigation.new(
      navigation: PreviewSupport.sample_navigation,
      site: Site.new(name: "Hulme & Moss Side", slug: "hulme-moss-side")
    )
  end
end
