# frozen_string_literal: true

class Views::Join::Home < Views::Join::Base
  prop :stats, Hash

  def view_template
    content_for(:title) { t('join.home.title') }
    content_for(:description) { t('join.home.description') }

    render_hero
    render_problem
    render_why_us
    render_plan
    render_audiences
    render_features
    render_purpose
    render_cta(heading: t('join.home.cta.heading'), body: t('join.home.cta.body'), button: t('join.home.cta.button'))
  end

  private

  def render_hero
    section(class: 'py-12 bg-home-background border-b border-rules') do
      div(class: 'container-public') do
        UI::Cluster(gap: :xl, justify: :between, wrap: false) do
          div do
            UI::Kicker(tone: :accent, spacing: :sm) { t('join.home.hero.kicker') }
            h1(class: 'join-headline m-0 mb-4') { t('join.home.hero.title') }
            UI::Text(measure: :prose, spacing: :lg) { t('join.home.hero.intro') }
            UI::Cluster(gap: :sm) do
              UI::Button(variant: :join, size: :lg, href: join_demo_path) { t('join.home.hero.cta_demo') }
              UI::Button(variant: :outline, href: join_our_story_path) { t('join.home.hero.cta_how') }
            end
          end
          image_tag('home/our_story/use_existing_tools.png', alt: '', class: 'hidden lg:block shrink-0 w-56 xl:w-72 h-auto')
        end
      end
    end
  end

  def render_problem
    section(class: 'py-10') do
      div(class: 'container-public') do
        UI::Grid(cols: { lg: 2 }, gap: :xl) do
          div do
            UI::Heading(spacing: :md) { t('join.home.problem.heading') }
            t('join.home.problem.paragraphs').each { |paragraph| UI::Text(measure: :prose) { paragraph } }
          end
          div do
            UI::Text(measure: :prose, spacing: :md) { t('join.home.problem.research_intro') }
            ul(class: 'list-none p-0 m-0') do
              t('join.home.problem.findings').each do |finding|
                li(class: 'py-2.5 border-b border-rules flex gap-3 items-start') do
                  span(class: 'text-secondary-deep mt-0.5') { icon(:check, size: '4') }
                  span { finding }
                end
              end
            end
            div(class: 'mt-5') do
              UI::Button(variant: :dark_outline, href: join_our_story_path) { t('join.home.problem.cta') }
            end
          end
        end
      end
    end
  end

  def render_why_us
    section(class: 'py-10 bg-home-background-3') do
      div(class: 'container-public grid lg:grid-cols-split-start gap-10 items-start') do
        div do
          UI::Heading(spacing: :md) { t('join.home.why_us.heading') }
          t('join.home.why_us.paragraphs').each { |paragraph| UI::Text(measure: :prose) { paragraph } }
        end
        UI::Stack(gap: :lg) do
          render_stats
          render_quote
        end
      end
    end
  end

  def render_stats
    # One column on phones, where the letterspaced labels overflow a half-width tile.
    UI::Grid(cols: { md: 2 }, gap: :sm) do
      stat_tile(@stats[:partnerships], t('join.home.stats.partnerships'))
      stat_tile(@stats[:partners], t('join.home.stats.partners'))
      stat_tile(@stats[:events], t('join.home.stats.events'))
      stat_tile(t('join.home.stats.conversations_value'), t('join.home.stats.conversations'))
    end
  end

  def stat_tile(value, label)
    UI::Card(variant: :highlight) do
      div(class: 'font-serif text-3xl leading-none') do
        plain value.is_a?(Numeric) ? value.to_fs(:delimited) : value.to_s
      end
      div(class: 'allcaps-label mt-1.5') { label }
    end
  end

  def render_quote
    blockquote(class: 'bg-home-background border-l-5 border-secondary-deep rounded-sm p-6 m-0') do
      p(class: 'font-serif text-card leading-snug mt-0 mb-3') { t('join.home.why_us.quote') }
      UI::Kicker(as: :footer, tone: :muted) { t('join.home.why_us.quote_by') }
    end
  end

  def render_plan
    section(class: 'py-10') do
      div(class: 'container-public') do
        UI::Stack(gap: :lg) do
          div do
            UI::Heading(spacing: :md) { t('join.home.plan.heading') }
            t('join.home.plan.paragraphs').each { |paragraph| UI::Text(measure: :prose) { paragraph } }
          end
          UI::Heading(level: 3, size: :subhead) { t('join.home.plan.ways_heading') }
          UI::Grid(cols: { md: 2 }) do
            Views::Join::Pricing::PACKAGE_KEYS.each { |key| render_package(key) }
          end
          div { UI::Button(variant: :outline, href: join_pricing_path) { t('join.home.plan.see_pricing') } }
        end
      end
    end
  end

  # Reads the pricing page's keys so the two pages describe the packages the same way.
  def render_package(key)
    UI::Card(tag: :article, padding: :lg) do
      UI::Heading(level: 4, size: :card, spacing: :sm) { t("join.pricing.packages.#{key}.name") }
      UI::Text(tone: :muted, spacing: :none) { t("join.pricing.packages.#{key}.what") }
    end
  end

  def render_audiences
    section(class: 'py-10 bg-cream') do
      div(class: 'container-public') do
        section_intro(
          kicker: t('join.home.audiences.kicker'),
          heading: t('join.home.audiences.heading'),
          lede: t('join.home.audiences.lede'),
          center: true
        )
        UI::Grid(cols: { md: 2, lg: 3 }) do
          Join::Base::AUDIENCE_KEYS.each { |key| Join::AudienceCard(audience: key) }
        end
      end
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
        UI::Grid(cols: { md: 2, lg: 3 }) do
          t('join.features.groups').each do |group|
            Join::FeatureCard(title: group[:title], body: group[:summary])
          end
        end
        div(class: 'text-center mt-6') do
          UI::Button(variant: :outline, href: join_features_path) do
            plain t('join.home.features.see_all')
            span { safe(' &rarr;') }
          end
        end
      end
    end
  end

  def render_purpose
    section(class: 'py-10 bg-home-background-3') do
      div(class: 'container-public') do
        UI::Heading(spacing: :md) { t('join.home.purpose.heading') }
        UI::Text(measure: :prose, spacing: :none) { t('join.home.purpose.body') }
      end
    end
  end
end
