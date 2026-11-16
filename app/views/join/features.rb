# frozen_string_literal: true

class Views::Join::Features < Views::Join::Base
  ISSUES_URL = 'https://github.com/geeksforsocialchange/PlaceCal/issues'

  def view_template
    content_for(:title) { t('join.features.title') }
    content_for(:description) { t('join.features.lede') }

    section(class: 'py-10') do
      div(class: 'container-public') do
        breadcrumb([t('join.nav.features')])
        h1(class: 'join-headline m-0 mb-2') { t('join.features.title') }
        UI::Text(measure: :prose, spacing: :xl) { t('join.features.lede') }
        UI::Stack(gap: :xl) do
          t('join.features.groups').each { |group| Join::FeatureGroup(group:) }
        end
      end
    end
    render_planned
  end

  private

  def render_planned
    section(class: 'py-10 bg-home-background-3', aria_labelledby: 'planned-heading') do
      div(class: 'container-public') do
        UI::Kicker(tone: :muted, spacing: :xs) { t('join.features.planned.kicker') }
        UI::Heading(id: 'planned-heading', spacing: :xs) { t('join.features.planned.title') }
        UI::Text(variant: :lede, tone: :muted, measure: :prose, spacing: :lg) { t('join.features.planned.lede') }
        UI::Grid(cols: { md: 2, lg: 4 }) do
          t('join.features.planned.items').each do |item|
            Join::FeatureCard(title: item[:title], body: item[:body])
          end
        end
        div(class: 'mt-4') do
          UI::Link(href: ISSUES_URL, variant: :action) do
            plain t('join.features.planned.link_label')
            span(aria_hidden: 'true') { safe(' &rarr;') }
          end
        end
      end
    end
  end
end
