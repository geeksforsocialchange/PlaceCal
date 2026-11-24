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

  # The closing call to action on the salmon band, shared by home and pricing.
  def render_cta(heading:, body:, kicker: nil)
    Join::Section(band: :salmon) do
      div(class: 'max-w-(--width-prose-md) mx-auto text-center') do
        UI::Stack(gap: :md, align: :center) do
          UI::Kicker { kicker } if kicker
          UI::Heading(size: :section, tone: :inherit, balance: true) { heading }
          UI::Text { body }
          UI::Button(variant: :ink, size: :lg, href: join_demo_path) { t('join.cta.button') }
        end
      end
    end
  end

  # A section's optional all-caps label over its serif heading. on_band takes the band's ink.
  def section_heading(heading, kicker: nil, on_band: false, size: :section)
    UI::Kicker(tone: on_band ? :inherit : :accent) { kicker } if kicker
    UI::Heading(size:, tone: on_band ? :inherit : :strong, balance: true) { heading }
  end
end
