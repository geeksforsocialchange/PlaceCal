# frozen_string_literal: true

# Shared base for the join marketing site pages (join.placecal.org, #3163).
# Copy lives under join.* in config/locales/join.en.yml; the audience keys
# are Components::Join::Base::AUDIENCE_KEYS.
class Views::Join::Base < Views::Base
  register_output_helper :icon

  private

  def audience_path(key)
    join_audience_path(key.tr('_', '-'))
  end

  # Absolute URL on the apex (the nationwide directory) from the join
  # subdomain, e.g. https://placecal.org/foo or http://lvh.me:3000/foo.
  # Mirrors Components::Join::Base#apex_url.
  def apex_url(path = '')
    "#{request.protocol}#{request.domain}#{request.port_string}#{path}"
  end

  # Breadcrumb trail on join page tops (the design's .bc) — taupe on cream,
  # or the AA-safe ink on salmon heroes (taupe only reaches 2.4:1 there).
  # Pass [label] for the current page, or [label, path] pairs for links.
  def breadcrumb(*crumbs, on_secondary: false)
    tone = on_secondary ? 'text-secondary-ink' : 'text-tertiary'
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
