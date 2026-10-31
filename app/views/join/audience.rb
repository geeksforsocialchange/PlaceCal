# frozen_string_literal: true

# One "Who it's for" pitch page; the controller has already validated the slug.
class Views::Join::Audience < Views::Join::Base
  prop :audience, String, reader: :private

  def view_template
    content_for(:title) { t("#{prefix}.title") }
    content_for(:description) { t("#{prefix}.lede") }

    render_hero
    render_pitch
    render_others
  end

  private

  def prefix
    "join.audiences.#{audience}"
  end

  def render_hero
    section(class: 'bg-secondary py-10') do
      div(class: 'container-public') do
        breadcrumb([t('join.breadcrumbs.audiences'), join_audiences_path], [t("#{prefix}.title")], on_secondary: true)
        UI::Kicker(tone: :strong, spacing: :sm) { t('join.audiences.for_kicker', audience: t("#{prefix}.title")) }
        h1(class: 'join-headline max-w-(--width-prose-lg) m-0 mb-4') { t("#{prefix}.hero") }
        UI::Text(tone: :strong, measure: :prose, spacing: :lg) { t("#{prefix}.subhero") }
        UI::Cluster(gap: :sm) do
          UI::Button(variant: :dark, href: join_demo_path) { t('join.audiences.cta_demo') }
          UI::Button(variant: :outline, href: join_features_path) { t('join.audiences.cta_features') }
        end
      end
    end
  end

  def render_pitch
    section(class: 'py-10') do
      div(class: 'container-public grid lg:grid-cols-split-start gap-10 items-start') do
        div do
          UI::Heading(spacing: :md) { t('join.audiences.how_heading') }
          UI::Text(spacing: :xl) { t("#{prefix}.details") }
          UI::Heading(spacing: :md) { t('join.audiences.impact_heading') }
          t("#{prefix}.impact").each do |impact|
            Join::FeatureCard(title: impact[:title], body: impact[:body])
          end
        end
        render_rollout
      end
    end
  end

  def render_rollout
    UI::Card(variant: :highlight, tag: :aside) do
      UI::Heading(size: :card, tone: :inherit, spacing: :none) { t('join.rollout.heading') }
      steps = t('join.rollout.steps')
      steps.each_with_index do |step, index|
        last = index == steps.length - 1
        div(class: "flex gap-5 items-start py-4 #{'border-b-2 border-rules' unless last}") do
          UI::CircleBadge(size: :md, tone: :background) { (index + 1).to_s }
          div do
            strong { step[:title] }
            p(class: 'text-sm m-0') { step[:body] }
          end
        end
      end
    end
  end

  def render_others
    keys = Join::Base::AUDIENCE_KEYS
    others = (keys - [audience]).rotate(keys.index(audience))

    section(class: 'py-10 bg-home-background-3') do
      div(class: 'container-public') do
        div(class: 'text-center mb-6') do
          UI::Kicker(tone: :muted, spacing: :xs) { t('join.audiences.others.kicker') }
          UI::Heading(spacing: :none) { t('join.audiences.others.heading') }
        end
        UI::Grid(cols: { md: 2, lg: 3 }) do
          others.first(3).each { |key| Join::AudienceCard(audience: key) }
        end
      end
    end
  end
end
