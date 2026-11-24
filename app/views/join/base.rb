# frozen_string_literal: true

# Base for join site pages. Copy lives under join.* in join.en.yml.
class Views::Join::Base < Views::Base
  include Components::Join::ApexUrl

  register_output_helper :icon

  private

  # Pass [label] for the current page, or [label, path] for a link.
  # on_secondary swaps to the darker ink, since taupe fails contrast on salmon.
  def breadcrumb(*crumbs, on_secondary: false)
    tone = on_secondary ? 'text-foreground-dark' : 'text-tertiary'
    nav(class: "text-sm #{tone} mb-3", aria_label: t('join.aria.breadcrumb')) do
      UI::Link(href: join_root_path, variant: :quiet, tone: :inherit) { t('join.breadcrumbs.root') }
      crumbs.each do |label, path|
        span(class: 'mx-1.5 opacity-60') { safe('&rsaquo;') }
        if path
          UI::Link(href: path, variant: :quiet, tone: :inherit) { label }
        else
          span { label }
        end
      end
    end
  end

  def render_cta(heading:, body:, kicker: nil)
    Join::ClosingCta(heading:, body:, kicker:)
  end

  # A section's optional all-caps label over its serif heading. on_band takes the band's ink.
  def section_heading(heading, kicker: nil, on_band: false, size: :section)
    UI::Kicker(tone: on_band ? :inherit : :accent) { kicker } if kicker
    UI::Heading(size:, tone: on_band ? :inherit : :strong, balance: true) { heading }
  end
end
