# frozen_string_literal: true

# Base for join site pages. Copy lives under join.* in join.en.yml.
class Views::Join::Base < Views::Base
  register_output_helper :icon

  private

  # Pass [label] for the current page, or [label, path] for a link.
  # on_secondary swaps to the darker ink, since taupe fails contrast on salmon.
  def breadcrumb(*crumbs, on_secondary: false)
    tone = on_secondary ? 'text-foreground-dark' : 'text-tertiary'
    nav(class: "text-xs #{tone} mb-3", aria_label: t('join.aria.breadcrumb')) do
      a(href: join_root_path, class: "with-no-sass #{tone} no-underline hover:underline") { t('join.breadcrumbs.root') }
      crumbs.each do |label, path|
        span(class: 'mx-1.5 opacity-60') { safe('&rsaquo;') }
        if path
          a(href: path, class: "with-no-sass #{tone} no-underline hover:underline") { label }
        else
          span { label }
        end
      end
    end
  end

  def section_intro(kicker:, heading:, lede: nil, center: false)
    div(class: "mb-7 #{'text-center' if center}") do
      div(class: 'allcaps-label text-tertiary mb-1') { kicker }
      h2(class: 'font-serif font-regular text-section text-foreground m-0') { heading }
      p(class: "text-detail text-tertiary leading-relaxed mt-2 mb-0 max-w-(--width-prose) #{'mx-auto' if center}") { lede } if lede
    end
  end
end
