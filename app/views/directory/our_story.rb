# frozen_string_literal: true

# Also served on the join site, which passes its own closing CTA path.
class Views::Directory::OurStory < Views::Base
  T = 'directory.pages.our_story'
  IMAGE_BASE = 'home/our_story'

  prop :cta_path, _Nilable(String), default: nil
  prop :root_label, _Nilable(String), default: nil
  prop :cta_label, _Nilable(String), default: nil

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
      breadcrumb_label: t("#{T}.heading"),
      root_label: @root_label,
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

  # Decisively narrower than the hero: a near-equal width reads as misaligned.
  def narrow(classes = '', &)
    div(class: "mx-auto max-w-(--width-prose-lg) px-6 #{classes}".strip, &)
  end

  def render_start
    section(class: 'pt-11 pb-9') do
      narrow do
        UI::Stack(gap: :lg) do
          eyebrow_heading(t("#{T}.start.eyebrow"), t("#{T}.start.heading"))
          div(class: 'grid md:grid-cols-2 gap-8') do
            t("#{T}.start.body").each do |paragraph|
              p(class: 'my-0 text-base leading-relaxed text-foreground') { paragraph }
            end
          end
          div(class: 'grid grid-cols-1 md:grid-cols-3 gap-3') do
            t("#{T}.stats").each { |stat| render_stat(stat) }
          end
        end
      end
    end
  end

  # Matches the homepage StatsStrip bead (Components::Directory::StatsStrip):
  # foreground numeral on a bordered cream card. The foreground brown also
  # clears WCAG AA on cream, unlike the previous lime/green.
  def render_stat(stat)
    UI::Card(padding: :sm, class: 'flex flex-col min-w-0') do
      span(class: 'font-serif text-stat leading-none text-foreground') { stat[:value] }
      span(class: 'allcaps-label text-tertiary mt-1.5 wrap-anywhere') { stat[:label] }
    end
  end

  def render_quote
    section(class: 'pb-10') do
      narrow do
        figure(class: 'border-l-6 border-primary m-0') do
          blockquote(class: 'mx-0 mt-0 mb-3.5 pl-8 font-serif text-display leading-tight text-foreground text-balance') do
            t("#{T}.quote.text")
          end
          figcaption(class: 'pl-8 text-base text-tertiary max-w-(--width-prose) leading-relaxed') { t("#{T}.quote.caption") }
        end
      end
    end
  end

  def eyebrow_heading(eyebrow, heading)
    UI::Stack(gap: :sm) do
      div(class: 'allcaps-label text-tertiary') { eyebrow }
      UI::Heading() { heading }
    end
  end

  def render_problems
    feature_section(:problems, PROBLEMS, wrapper_class: 'bg-home-background border-t-5 border-rules py-11')
  end

  def render_solutions
    feature_section(:solutions, SOLUTIONS, wrapper_class: 'pt-11 pb-3')
  end

  def feature_section(section_key, items, wrapper_class:)
    section(class: wrapper_class) do
      narrow do
        UI::Stack(gap: :xl) do
          eyebrow_heading(t("#{T}.#{section_key}.eyebrow"), t("#{T}.#{section_key}.heading"))
          items.each { |feature| render_feature(section_key, feature) }
        end
      end
    end
  end

  def render_feature(section_key, feature)
    base = "#{T}.#{section_key}.#{feature[:key]}"

    div(class: 'grid md:grid-cols-2 gap-11 items-center') do
      div(class: "grid place-items-center p-2 #{'md:order-2' if feature[:flip]}".strip) do
        image_tag "#{IMAGE_BASE}/#{feature[:image]}",
                  alt: t("#{base}.image_alt"),
                  class: 'w-full max-w-76 h-auto object-contain'
      end
      UI::Stack(gap: :sm) do
        UI::Cluster(gap: :sm, align: :baseline) do
          # Deepened coral (vs --color-secondary-deep) so the large numeral clears WCAG AA (3:1) on cream.
          span(class: 'font-serif text-2xl leading-none text-secondary-dark') { feature[:num] } if feature[:num]
          span(class: 'allcaps-label text-tertiary') { t("#{base}.kicker") }
        end
        h3(class: 'text-subhead leading-tight font-bold text-foreground') { t("#{base}.title") }
        p(class: 'text-base leading-relaxed text-tertiary') { t("#{base}.body") }
      end
    end
  end

  def render_turning
    section(class: 'bg-secondary text-foreground py-13') do
      narrow('text-center') do
        UI::Stack(gap: :lg) do
          UI::Stack(gap: :md) do
            h2(class: 'mx-auto max-w-(--width-prose-lg) font-serif font-regular text-display leading-tight text-foreground text-balance') do
              t("#{T}.turning.heading")
            end
            # --color-foreground-dark (the design's text-on-colour brown) clears WCAG AA on the pink panel; the prior opacity-85 brown did not.
            p(class: 'mx-auto max-w-(--width-prose) text-base leading-relaxed text-foreground-dark') do
              t("#{T}.turning.body")
            end
          end
          div { image_tag "#{IMAGE_BASE}/logo_onpink.svg", alt: t("#{T}.turning.logo_alt"), class: 'inline h-10' }
        end
      end
    end
  end

  def render_cta
    section(class: 'pt-12 pb-4') do
      narrow do
        UI::Card(variant: :highlight, padding: :xl) do
          UI::Cluster(gap: :lg, justify: :between) do
            h2(class: 'my-0 font-serif font-regular text-display leading-tight') do
              t("#{T}.cta.heading")
            end
            UI::Button(variant: :light, size: :lg, href: @cta_path || get_in_touch_path) do
              plain @cta_label || t("#{T}.cta.button")
              span(aria_hidden: 'true') { safe('→') }
            end
          end
        end
      end
    end
  end
end
