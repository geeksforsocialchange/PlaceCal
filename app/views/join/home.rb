# frozen_string_literal: true

class Views::Join::Home < Views::Join::Base
  prop :stats, Hash

  def view_template
    content_for(:title) { t('join.home.title') }
    content_for(:description) { t('join.home.description') }

    render_hero
    render_audiences
    render_why
    render_features
    render_cta
  end

  private

  def render_hero
    section(class: 'py-12 bg-home-background border-b border-rules') do
      div(class: 'container-public grid lg:grid-cols-[1.3fr_1fr] gap-10 items-center') do
        div do
          div(class: 'allcaps-label text-secondary-strong mb-2') { t('join.home.hero.kicker') }
          h1(class: 'join-headline m-0 mb-4') { t('join.home.hero.title') }
          p(class: 'text-base leading-relaxed max-w-(--width-prose) mt-0 mb-6') { t('join.home.hero.intro') }
          div(class: 'flex gap-2.5 flex-wrap items-center') do
            a(href: join_demo_path, class: 'btn-join') { t('join.home.hero.cta_demo') }
            a(href: join_our_story_path, class: 'btn-primary-outline') { t('join.home.hero.cta_how') }
          end
        end
        render_stats
      end
    end
  end

  def render_stats
    div(class: 'grid grid-cols-2 gap-2.5') do
      stat_tile(@stats[:partnerships], t('join.home.stats.partnerships'))
      stat_tile(@stats[:partners], t('join.home.stats.partners'))
      stat_tile(@stats[:events], t('join.home.stats.events'))
      stat_tile(t('join.home.stats.residents_value'), t('join.home.stats.residents'))
    end
  end

  def stat_tile(value, label)
    div(class: 'bg-secondary rounded-card p-5') do
      div(class: 'font-serif text-[2.4rem] leading-none text-secondary-ink') do
        plain value.is_a?(Numeric) ? value.to_fs(:delimited) : value.to_s
      end
      div(class: 'allcaps-label text-secondary-ink mt-1.5') { label }
    end
  end

  def render_audiences
    section(class: 'py-10') do
      div(class: 'container-public') do
        section_intro(
          kicker: t('join.home.audiences.kicker'),
          heading: t('join.home.audiences.heading'),
          lede: t('join.home.audiences.lede'),
          center: true
        )
        div(class: 'grid md:grid-cols-2 lg:grid-cols-3 gap-4') do
          Join::Base::AUDIENCE_KEYS.each { |key| Join::AudienceCard(audience: key) }
        end
      end
    end
  end

  def render_why
    section(class: 'py-10 bg-home-background-3') do
      div(class: 'container-public grid lg:grid-cols-[1fr_1.2fr] gap-10 items-center') do
        div do
          div(class: 'allcaps-label text-tertiary mb-1') { t('join.home.why.kicker') }
          h2(class: 'font-serif font-regular text-section text-foreground m-0 mb-3') { t('join.home.why.heading') }
          p(class: 'mt-0 mb-4') { t('join.home.why.intro') }
          ul(class: 'list-none p-0 m-0') do
            t('join.home.why.problems').each do |problem|
              li(class: 'py-2.5 border-b border-rules flex gap-3 items-start') do
                span(class: 'text-secondary-deep mt-0.5') { icon(:check, size: '4') }
                span { problem }
              end
            end
          end
          div(class: 'mt-5') do
            a(href: join_our_story_path, class: 'btn-dark-outline') { t('join.home.why.cta') }
          end
        end
        render_quote
      end
    end
  end

  def render_quote
    blockquote(class: 'bg-home-background border-l-[5px] border-secondary-deep rounded-sm p-6 m-0') do
      p(class: 'font-serif text-card leading-snug m-0') { t('join.home.why.quote') }
      footer(class: 'allcaps-label text-tertiary mt-3') { t('join.home.why.quote_by') }
    end
  end

  def render_features
    section(class: 'py-10') do
      div(class: 'container-public') do
        section_intro(
          kicker: t('join.home.features.kicker'),
          heading: t('join.home.features.heading'),
          center: true
        )
        div(class: 'grid md:grid-cols-2 lg:grid-cols-3 gap-4') do
          t('join.features.list').first(6).each do |feature|
            Join::FeatureCard(title: feature[:title], body: feature[:body])
          end
        end
        div(class: 'text-center mt-6') do
          a(href: join_features_path, class: 'btn-primary-outline') do
            plain t('join.home.features.see_all')
            span { safe(' &rarr;') }
          end
        end
      end
    end
  end

  def render_cta
    section(class: 'py-12 bg-secondary') do
      div(class: 'container-narrow text-center') do
        h2(class: 'font-serif font-regular text-[2.2rem] leading-tight text-secondary-ink m-0 mb-3') { t('join.home.cta.heading') }
        p(class: 'text-base leading-relaxed text-secondary-ink mt-0 mb-6') { t('join.home.cta.body') }
        a(href: join_demo_path, class: 'btn-dark') { t('join.home.cta.button') }
      end
    end
  end
end
