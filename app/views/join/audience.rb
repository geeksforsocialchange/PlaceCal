# frozen_string_literal: true

# One "Who it's for" pitch page. The audience key is validated by the
# controller against Join::Base::AUDIENCE_KEYS.
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
        div(class: 'allcaps-label text-secondary-ink mb-2') do
          t('join.audiences.for_kicker', audience: t("#{prefix}.title").downcase)
        end
        h1(class: 'join-headline max-w-(--width-prose-lg) m-0 mb-4') { t("#{prefix}.hero") }
        p(class: 'text-base leading-relaxed text-secondary-ink max-w-(--width-prose) mt-0 mb-6') { t("#{prefix}.subhero") }
        div(class: 'flex gap-2.5 flex-wrap items-center') do
          a(href: join_demo_path, class: 'btn-dark') { t('join.audiences.cta_demo') }
          a(href: join_features_path, class: 'btn-primary-outline') { t('join.audiences.cta_features') }
        end
      end
    end
  end

  def render_pitch
    section(class: 'py-10') do
      div(class: 'container-public grid lg:grid-cols-[1.4fr_1fr] gap-10 items-start') do
        div do
          h2(class: 'font-serif font-regular text-section text-foreground mt-0 mb-3') { t('join.audiences.how_heading') }
          p(class: 'text-base leading-relaxed mt-0 mb-8') { t("#{prefix}.details") }
          h2(class: 'font-serif font-regular text-section text-foreground mt-0 mb-4') { t('join.audiences.impact_heading') }
          t("#{prefix}.impact").each do |impact|
            Join::FeatureCard(title: impact[:title], body: impact[:body])
          end
        end
        render_rollout
      end
    end
  end

  def render_rollout
    aside(class: 'bg-secondary rounded-card p-5 text-secondary-ink') do
      h2(class: 'font-serif font-regular text-card text-secondary-ink m-0') { t('join.rollout.heading') }
      steps = t('join.rollout.steps')
      steps.each_with_index do |step, index|
        last = index == steps.length - 1
        div(class: "grid grid-cols-[60px_1fr] gap-5 items-start py-4 #{'border-b-2 border-rules' unless last}") do
          div(class: 'w-[60px] h-[60px] rounded-full bg-home-background text-foreground grid place-items-center font-serif text-[1.6rem]') do
            plain (index + 1).to_s
          end
          div do
            strong { step[:title] }
            p(class: 'text-sm m-0') { step[:body] }
          end
        end
      end
    end
  end

  def render_others
    others = Join::Base::AUDIENCE_KEYS - [audience]

    section(class: 'py-10 bg-home-background-3') do
      div(class: 'container-public') do
        div(class: 'text-center mb-6') do
          div(class: 'allcaps-label text-tertiary mb-1') { t('join.audiences.others.kicker') }
          h2(class: 'font-serif font-regular text-section text-foreground m-0') { t('join.audiences.others.heading') }
        end
        div(class: 'grid md:grid-cols-2 lg:grid-cols-3 gap-4') do
          others.first(3).each { |key| Join::AudienceCard(audience: key) }
        end
      end
    end
  end
end
