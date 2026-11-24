# frozen_string_literal: true

class Views::Join::Home < Views::Join::Base
  # Each drawing carries its own step number.
  STEP_IMAGES = %w[home/how/1.png home/how/2.png home/how/3.png].freeze

  def view_template
    content_for(:title) { t('join.home.title') }
    content_for(:description) { t('join.home.description') }

    render_hero
    render_problem
    render_approach
    render_how
    render_difference
    render_features
    render_cta(kicker: t('join.home.cta.kicker'), heading: t('join.home.cta.heading'), body: t('join.home.cta.body'))
  end

  private

  def render_hero
    Join::Section(band: :salmon) do
      Join::Columns(align: :center) do |c|
        c.column(8) do
          UI::Stack(gap: :lg, align: :start) do
            h1(class: 'join-headline text-foreground-darker') { t('join.home.hero.title') }
            UI::Text(variant: :intro) { t('join.home.hero.intro') }
            UI::Cluster(gap: :md) do
              UI::Button(variant: :ink, size: :lg, href: join_demo_path) { t('join.cta.button') }
              UI::Button(variant: :ink_outline, size: :lg, href: '#how-it-works') { t('join.home.hero.cta_how') }
            end
          end
        end
        c.column(4) do
          # The page colour behind the drawing keeps its salmon circle from vanishing into the band.
          image_tag('home/our_story/use_existing_tools.png', alt: t('join.home.hero.image_alt'),
                                                             class: 'block w-full h-auto rounded-card bg-home-background p-6')
        end
      end
    end
  end

  def render_problem
    Join::Section() do
      UI::Stack(gap: :xl, align: :start) do
        Join::Columns() do |c|
          c.column(8) do
            UI::Stack(gap: :md) do
              section_heading(t('join.home.problem.heading'), kicker: t('join.home.problem.kicker'))
              t('join.home.problem.paragraphs').each { |paragraph| UI::Text(measure: :prose_md) { paragraph } }
            end
          end
          c.column(4) { Join::Quote(text: t('join.home.problem.quote'), by: t('join.home.problem.quote_by')) }
        end
        UI::Button(variant: :ink_outline, href: join_our_story_path) { t('join.home.problem.cta') }
      end
    end
  end

  def render_approach
    Join::Section(band: :tint) do
      Join::Columns(align: :center) do |c|
        c.column(8) do
          UI::Stack(gap: :md) do
            section_heading(t('join.home.approach.heading'), kicker: t('join.home.approach.kicker'))
            t('join.home.approach.paragraphs').each { |paragraph| UI::Text(measure: :prose_md) { paragraph } }
            UI::Text(measure: :prose_md) { strong { t('join.home.approach.closing') } }
          end
        end
        c.column(4) do
          image_tag('join/hulme-park-winter.jpg', alt: t('join.home.approach.image_alt'),
                                                  class: 'block w-full h-auto rounded-card')
        end
      end
    end
  end

  def render_how
    Join::Section(id: 'how-it-works') do
      UI::Stack(gap: :xl) do
        Join::Columns() do |c|
          c.column(8) do
            UI::Stack(gap: :md) { section_heading(t('join.home.how.heading'), kicker: t('join.home.how.kicker')) }
          end
        end
        render_steps
        Join::Columns() do |c|
          c.column(8) do
            UI::Stack(gap: :lg, align: :start) do
              UI::Text(measure: :prose_md) { t('join.home.how.body') }
              UI::Button(variant: :join, size: :lg, href: join_pricing_path) { t('join.home.how.cta') }
            end
          end
          c.column(4) { Join::Quote(text: t('join.home.how.quote'), by: t('join.home.how.quote_by')) }
        end
      end
    end
  end

  def render_steps
    Join::Columns(as: :ol) do |c|
      t('join.home.how.steps').zip(STEP_IMAGES).each do |step, image|
        c.column(4, as: :li) do
          UI::Stack(gap: :md) do
            image_tag(image, alt: '', class: 'block w-full max-w-72 h-auto')
            div(class: 'pt-4 border-t-4 border-primary') { UI::Heading(level: 3, size: :card, tone: :strong) { step } }
          end
        end
      end
    end
  end

  def render_difference
    Join::Section(band: :green) do
      Join::Columns() do |c|
        c.column(8) do
          UI::Stack(gap: :md) do
            section_heading(t('join.home.difference.heading'), kicker: t('join.home.difference.kicker'), on_band: true)
            UI::Text(measure: :prose_md) { t('join.home.difference.body') }
          end
        end
        c.column(4) { Join::Quote(text: t('join.home.difference.quote'), by: t('join.home.difference.quote_by'), tone: :on_primary) }
      end
    end
  end

  def render_features
    Join::Section(band: :cream, padding: :slim) do
      UI::Stack(gap: :lg, align: :start) do
        UI::Stack(gap: :sm) do
          section_heading(t('join.home.features.heading'), kicker: t('join.home.features.kicker'), size: :subhead)
        end
        Join::Columns(as: :ul, row_gap: :sm) do |c|
          t('join.features.groups').each do |group|
            c.column(4, as: :li) do
              div(class: 'flex items-start gap-3 font-bold text-foreground-dark') do
                span(class: 'text-secondary-strong pt-0.5') { icon(:check, size: '5') }
                span { group[:title] }
              end
            end
          end
        end
        UI::Button(variant: :ink_outline, href: join_features_path) { t('join.home.features.see_all') }
      end
    end
  end
end
