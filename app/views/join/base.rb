# frozen_string_literal: true

# Shared base for the join marketing site pages (join.placecal.org, #3163).
# Copy lives under join.* in config/locales/join.en.yml; the audience keys
# are Components::Join::Base::AUDIENCES.
class Views::Join::Base < Views::Base
  register_output_helper :icon

  private

  def audience_path(key)
    join_audience_path(key.tr('_', '-'))
  end

  # Taupe breadcrumb trail on cream/salmon page tops (the design's .bc).
  # Pass [label] for the current page, or [label, path] pairs for links.
  def breadcrumb(*crumbs)
    nav(class: 'text-xs text-tertiary mb-3', aria_label: t('join.aria.breadcrumb')) do
      a(href: join_root_path, class: 'with-no-sass text-tertiary no-underline hover:underline') { t('join.breadcrumbs.root') }
      crumbs.each do |label, path|
        span(class: 'mx-1.5 opacity-60') { safe('&rsaquo;') }
        if path
          a(href: path, class: 'with-no-sass text-tertiary no-underline hover:underline') { label }
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
