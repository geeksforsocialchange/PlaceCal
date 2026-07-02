# frozen_string_literal: true

# Header for the join site: a salmon band cross-linking back to the directory,
# then the shared nil-site navigation with a "Book a demo" CTA.
class Components::Join::Header < Components::Join::Base
  def view_template
    render_band
    render Components::Shared::Navigation.new(
      navigation: nav_items,
      site: nil,
      cta_label: t('join.nav.book_demo'),
      cta_path: join_demo_path
    )
  end

  private

  # A nav landmark (not a bare div) so the band's content is contained by a
  # landmark — axe's region rule flags top-level content outside one.
  def render_band
    nav(class: 'bg-secondary', aria_label: t('join.band.aria_label')) do
      div(class: 'container-public py-2 flex items-center justify-between gap-4 flex-wrap') do
        span(class: 'allcaps-label text-secondary-ink') { t('join.band.host') }
        a(href: apex_url, class: 'with-no-sass allcaps-label text-secondary-ink no-underline hover:underline') do
          plain "← #{t('join.band.directory_link')}"
        end
      end
    end
  end

  def nav_items
    [
      [t('join.nav.audiences'), join_audiences_path],
      [t('join.nav.features'), join_features_path],
      [t('join.nav.our_story'), join_our_story_path],
      [t('join.nav.pricing'), join_pricing_path]
    ]
  end
end
