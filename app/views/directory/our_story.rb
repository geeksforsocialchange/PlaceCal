# frozen_string_literal: true

# PlaceCal's origin & mission narrative, rebuilt in the directory (Firehose)
# design system. A narrow (960px) editorial page: hero, the research that
# started it, three problems, a turning point, the three-part solution, and a
# call to action. Copy lives under directory.pages.our_story in en.yml.
class Views::Directory::OurStory < Views::Base
  T = 'directory.pages.our_story'
  IMAGE_BASE = 'home/our_story'

  # Alternating illustration/text rows — rows 1 & 3 image-left, row 2 image-right.
  PROBLEMS = [
    { key: :people, num: '01', image: 'not_together.png', flip: false },
    { key: :software, num: '02', image: 'current_software.png', flip: true },
    { key: :skills, num: '03', image: 'no_tech_skills.png', flip: false }
  ].freeze

  SOLUTIONS = [
    { key: :ownership, image: 'collective_ownership.png', flip: false },
    { key: :technology, image: 'use_existing_tools.png', flip: true },
    { key: :people, image: 'training.png', flip: false }
  ].freeze

  def view_template
    content_for(:title) { t("#{T}.heading") }

    Directory::PageHero(
      narrow: true,
      breadcrumb_label: t("#{T}.heading"),
      kicker: t("#{T}.heading"),
      title: t("#{T}.hero_title"),
      subtitle: t("#{T}.hero_lede")
    )

    render_start
    render_quote
    render_problems
    render_turning
    render_solutions
    render_cta
  end

  private

  def narrow(classes = '', &)
    div(class: "container-editorial #{classes}".strip, &)
  end

  def render_start
    section(class: 'pt-11 pb-9') do
      narrow do
        div(class: 'allcaps-label text-tertiary mb-2') { t("#{T}.start.eyebrow") }
        h2(class: 'font-serif font-regular text-section text-foreground mt-0 mb-5') { t("#{T}.start.heading") }
        div(class: 'grid md:grid-cols-2 gap-8') do
          t("#{T}.start.body").each do |paragraph|
            p(class: 'my-0 text-[1.02rem] leading-[1.6] text-foreground') { paragraph }
          end
        end
        div(class: 'grid grid-cols-1 md:grid-cols-3 gap-3 mt-7') do
          t("#{T}.stats").each { |stat| render_stat(stat) }
        end
      end
    end
  end

  # Matches the homepage StatsStrip bead (Components::Directory::StatsStrip):
  # foreground numeral on a bordered cream card. The foreground brown also
  # clears WCAG AA on cream, unlike the previous lime/green.
  def render_stat(stat)
    div(class: 'flex flex-col bg-home-background border-2 border-rules rounded-card py-3.5 px-4.5 min-w-0') do
      span(class: 'font-serif text-stat leading-none text-foreground') { stat[:value] }
      span(class: 'allcaps-label text-tertiary mt-1.5 wrap-anywhere') { stat[:label] }
    end
  end

  def render_quote
    section(class: 'pb-10') do
      narrow do
        figure(class: 'border-l-[6px] border-primary m-0') do
          blockquote(class: 'mx-0 mt-0 mb-3.5 pl-8 font-serif text-[clamp(1.7rem,3.4vw,2.4rem)] leading-[1.18] text-foreground text-balance') do
            t("#{T}.quote.text")
          end
          figcaption(class: 'pl-8 text-base text-tertiary max-w-[560px] leading-[1.55]') { t("#{T}.quote.caption") }
        end
      end
    end
  end

  def render_problems
    feature_section(:problems, PROBLEMS, eyebrow_class: 'text-tertiary',
                                         wrapper_class: 'bg-home-background border-t-[5px] border-rules py-11')
  end

  def render_solutions
    feature_section(:solutions, SOLUTIONS, eyebrow_class: 'text-tertiary', wrapper_class: 'pt-11 pb-3')
  end

  def feature_section(section_key, items, eyebrow_class:, wrapper_class:)
    section(class: wrapper_class) do
      narrow do
        div(class: "allcaps-label #{eyebrow_class} mb-2") { t("#{T}.#{section_key}.eyebrow") }
        h2(class: 'font-serif font-regular text-section text-foreground mt-0 mb-9') { t("#{T}.#{section_key}.heading") }
        div(class: 'flex flex-col gap-12') do
          items.each { |feature| render_feature(section_key, feature) }
        end
      end
    end
  end

  def render_feature(section_key, feature)
    base = "#{T}.#{section_key}.#{feature[:key]}"

    div(class: 'grid md:grid-cols-[0.85fr_1fr] gap-11 items-center') do
      div(class: "grid place-items-center p-2 #{'md:order-2' if feature[:flip]}".strip) do
        image_tag "#{IMAGE_BASE}/#{feature[:image]}",
                  alt: t("#{base}.image_alt"),
                  class: 'w-full max-w-[340px] h-auto object-contain'
      end
      div do
        div(class: 'flex items-baseline gap-2.5 mb-2') do
          # Deepened coral (vs --color-secondary-deep) so the large numeral clears WCAG AA (3:1) on cream.
          span(class: 'font-serif text-[1.9rem] leading-none -tracking-[0.02em]', style: 'color: #d65a52') { feature[:num] } if feature[:num]
          span(class: 'allcaps-label text-tertiary') { t("#{base}.kicker") }
        end
        h3(class: 'mt-0 mb-2 text-[1.45rem] leading-[1.15] font-bold text-foreground') { t("#{base}.title") }
        p(class: 'my-0 text-base leading-[1.6] text-tertiary') { t("#{base}.body") }
      end
    end
  end

  def render_turning
    section(class: 'bg-secondary text-foreground py-[3.25rem]') do
      narrow('text-center') do
        h2(class: 'mx-auto mt-0 mb-4 max-w-[760px] font-serif font-regular text-[clamp(1.9rem,3.8vw,2.6rem)] leading-[1.12] text-foreground text-balance') do
          t("#{T}.turning.heading")
        end
        # #43392f (the design's text-on-colour brown) clears WCAG AA on the pink panel; the prior opacity-85 brown did not.
        p(class: 'mx-auto my-0 max-w-[560px] text-[1.05rem] leading-[1.55]', style: 'color: #43392f') do
          t("#{T}.turning.body")
        end
        image_tag "#{IMAGE_BASE}/logo_onpink.svg", alt: t("#{T}.turning.logo_alt"), class: 'inline h-[46px] mt-7'
      end
    end
  end

  def render_cta
    section(class: 'pt-12 pb-4') do
      narrow do
        div(class: 'flex flex-wrap items-center justify-between gap-6 rounded-card bg-secondary text-foreground px-[2.4rem] py-[2.1rem]') do
          h2(class: 'my-0 font-serif font-regular text-[clamp(1.5rem,3vw,2rem)] leading-[1.1] text-foreground') do
            t("#{T}.cta.heading")
          end
          link_to get_in_touch_path,
                  class: 'with-no-sass inline-flex items-center gap-2 rounded-full border-2 border-home-background bg-home-background px-6 py-[0.7rem] text-base font-bold text-foreground no-underline transition-colors hover:border-foreground hover:bg-foreground hover:text-background' do
            plain t("#{T}.cta.button")
            span(aria_hidden: 'true') { safe('→') }
          end
        end
      end
    end
  end
end
