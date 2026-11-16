# frozen_string_literal: true

class Views::Join::Features < Views::Join::Base
  ISSUES_URL = 'https://github.com/geeksforsocialchange/PlaceCal/issues'

  def view_template
    content_for(:title) { t('join.features.title') }
    content_for(:description) { t('join.features.lede') }

    Directory::PageHero(
      breadcrumb_label: t('join.nav.features'),
      root_label: t('join.breadcrumbs.root'),
      title: t('join.features.title'),
      subtitle: t('join.features.lede')
    )

    t('join.features.groups').each_with_index { |group, index| Join::FeatureGroup(group:, banded: index.even?) }
    render_planned
  end

  private

  def render_planned
    section(class: 'py-12 bg-home-background-3', aria_labelledby: 'planned-heading') do
      div(class: 'container-public') do
        UI::Kicker(tone: :muted, spacing: :xs) { t('join.features.planned.kicker') }
        UI::Heading(id: 'planned-heading', spacing: :xs) { t('join.features.planned.title') }
        UI::Text(variant: :lede, tone: :muted, measure: :prose, spacing: :lg, pretty: true) { t('join.features.planned.lede') }
        UI::Grid(cols: { md: 2, lg: 4 }) do
          t('join.features.planned.items').each do |item|
            Join::FeatureCard(title: item[:title], body: item[:body], icon: item[:icon]&.to_sym)
          end
        end
        div(class: 'mt-4') do
          UI::Button(variant: :dark, href: ISSUES_URL) do
            plain t('join.features.planned.link_label')
            span(aria_hidden: 'true') { safe(' &rarr;') }
          end
        end
      end
    end
  end
end
