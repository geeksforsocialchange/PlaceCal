# frozen_string_literal: true

# The pricing page (July 2026 model): three paid tiers priced by who you
# are, compared in a table on wide screens and stacked cards under 900px,
# with a free Starter strip, extras, the shared four-step rollout as a
# timeline, and a native-details FAQ. No JavaScript anywhere.
class Views::Join::Pricing < Views::Join::Base
  TIER_KEYS = %i[community organisation institution].freeze

  # Same illustrations the rollout steps use on the old Our Story page.
  ROLLOUT_ART = %w[
    home/our_story/training.png
    home/our_story/not_together.png
    home/our_story/use_existing_tools.png
    home/our_story/current_software.png
  ].freeze

  def view_template
    content_for(:title) { t('join.pricing.title') }
    content_for(:description) { t('join.pricing.description') }

    render_hero
    render_tiers
    render_extras
    render_rollout
    render_faq
  end

  private

  def render_hero
    section(class: 'bg-secondary py-10') do
      div(class: 'container-public') do
        breadcrumb([t('join.nav.pricing')], on_secondary: true)
        div(class: 'flex items-center justify-between gap-8') do
          div do
            div(class: 'allcaps-label text-secondary-ink mb-2') { t('join.pricing.eyebrow') }
            h1(class: 'join-headline m-0') { t('join.pricing.title') }
          end
          image_tag('home/our_story/collective_ownership.png', alt: '',
                                                               class: 'hidden min-[680px]:block shrink-0 w-[clamp(140px,18vw,220px)] h-auto')
        end
      end
    end
  end

  def render_tiers
    section(class: 'py-10') do
      div(class: 'container-public') do
        render_compare_table
        render_tier_cards
        render_starter_strip
        div(class: 'text-center mt-7') do
          a(href: join_demo_path, class: 'btn-join') { t('join.pricing.cta') }
        end
      end
    end
  end

  # Desktop (≥900px): a semantic comparison table. The design's hard
  # requirement is that this must never squish — under 900px it is hidden
  # entirely and the stacked cards below take over.
  def render_compare_table
    div(class: 'hidden min-[900px]:block') do
      table(class: 'w-full border-collapse table-fixed') do
        caption(class: 'sr-only') { t('join.pricing.table.caption') }
        colgroup do
          col(class: 'w-1/4')
          TIER_KEYS.each { col }
        end
        thead do
          tr do
            td
            TIER_KEYS.each { |tier| render_tier_column_header(tier) }
          end
        end
        tbody do
          t('join.pricing.rows').each { |row| render_compare_row(row) }
          tr do
            th(scope: 'colgroup', colspan: 4,
               class: 'allcaps-label text-secondary-strong text-left px-4 pt-6 pb-2 border-b-2 border-rules') do
              t('join.pricing.table.support_heading')
            end
          end
          t('join.pricing.support_rows').each { |row| render_compare_row(row) }
        end
      end
    end
  end

  def render_tier_column_header(tier)
    th(scope: 'col', class: 'text-left align-top px-4 pb-4 border-b-2 border-foreground') do
      div(class: 'allcaps-label text-secondary-strong') { t("join.pricing.tiers.#{tier}.name") }
      p(class: 'font-serif text-[1.02rem] leading-tight text-foreground mt-2 mb-2.5 min-h-[2.4em]') do
        t("join.pricing.tiers.#{tier}.who")
      end
      div(class: 'font-serif text-[2rem] leading-none text-foreground whitespace-nowrap') do
        span(class: 'text-[0.95rem] text-tertiary') { "#{t('join.pricing.from')} " } if tier_from?(tier)
        plain t("join.pricing.tiers.#{tier}.price")
        span(class: 'text-[0.95rem] text-tertiary') { t('join.pricing.per_month') }
      end
      div(class: 'text-[0.85rem] text-tertiary mt-2 whitespace-nowrap') { t("join.pricing.tiers.#{tier}.setup") }
    end
  end

  def render_compare_row(row)
    tr do
      th(scope: 'row', class: 'text-left align-top font-bold text-foreground text-[0.98rem] px-4 py-3.5 border-b border-rules') do
        row[:label]
      end
      row[:values].each do |value|
        td(class: 'align-top px-4 py-3.5 border-b border-rules text-[0.98rem] leading-normal') do
          case value
          when true then included_mark
          when false then excluded_mark
          else plain value
          end
        end
      end
    end
  end

  def included_mark
    tick
    span(class: 'sr-only') { t('join.pricing.table.included') }
  end

  def excluded_mark
    span(class: 'text-rules text-[1.1rem]', aria_hidden: 'true') { '–' }
    span(class: 'sr-only') { t('join.pricing.table.not_included') }
  end

  def tick(size: 20)
    svg(width: size.to_s, height: size.to_s, viewBox: '0 0 24 24', fill: 'none',
        stroke: 'currentColor', stroke_width: '2.5', stroke_linecap: 'round', stroke_linejoin: 'round',
        class: 'inline-flex shrink-0 text-secondary-deep', aria_hidden: 'true') do |s|
      s.polyline(points: '20 6 9 17 4 12')
    end
  end

  # Mobile (<900px): one stacked card per paid tier. No buttons on cards.
  def render_tier_cards
    div(class: 'grid gap-4 min-[900px]:hidden') do
      TIER_KEYS.each { |tier| render_tier_card(tier) }
    end
  end

  def render_tier_card(tier)
    article(class: 'flex flex-col bg-cream border-2 border-rules rounded-card p-6') do
      div(class: 'allcaps-label text-secondary-strong') { t("join.pricing.tiers.#{tier}.name") }
      p(class: 'font-serif text-[1.24rem] leading-snug text-foreground mt-2.5 mb-3') do
        t("join.pricing.tiers.#{tier}.who_card")
      end
      div(class: 'font-serif text-[2.3rem] leading-none text-foreground') do
        span(class: 'block text-[0.95rem] text-tertiary mb-0.5') { t('join.pricing.from') } if tier_from?(tier)
        plain t("join.pricing.tiers.#{tier}.price")
        span(class: 'text-[0.95rem] text-tertiary') { " #{t('join.pricing.per_month')}" }
      end
      div(class: 'text-[0.85rem] text-tertiary mt-1.5 pb-4 border-b-2 border-rules mb-4') do
        t("join.pricing.tiers.#{tier}.setup_card")
      end
      div(class: 'text-[0.85rem] text-tertiary mb-4') do
        b(class: 'font-serif font-regular text-[1.15rem] text-foreground') { t("join.pricing.tiers.#{tier}.spec_strong") }
        plain t("join.pricing.tiers.#{tier}.spec_rest")
      end
      ul(class: 'list-none p-0 m-0 flex flex-col gap-2.5') do
        t("join.pricing.tiers.#{tier}.bullets").each do |bullet|
          li(class: 'flex gap-2.5 text-[0.94rem] leading-snug') do
            tick(size: 18)
            plain bullet
          end
        end
      end
    end
  end

  # The free tier is deliberately pulled out of the comparison, not a
  # fourth column.
  def render_starter_strip
    aside(class: 'bg-cream-warm border-2 border-rules rounded-card px-7 py-6 mt-6 grid min-[680px]:grid-cols-[auto_1fr] gap-x-10 gap-y-3 items-center') do
      div do
        div(class: 'allcaps-label text-secondary-strong') { t('join.pricing.starter.name') }
        div(class: 'font-serif text-[1.8rem] leading-tight text-foreground') { t('join.pricing.starter.price') }
      end
      div do
        t('join.pricing.starter.body').each_with_index do |paragraph, index|
          p(class: "text-base leading-relaxed text-foreground max-w-(--width-prose) mb-0 #{index.zero? ? 'mt-0' : 'mt-2.5'}") do
            paragraph
          end
        end
      end
    end
  end

  def render_extras
    section(class: 'py-10 bg-cream') do
      div(class: 'container-public') do
        h2(class: 'font-serif font-regular text-section text-foreground mt-0 mb-7') { t('join.pricing.extras.heading') }
        div(class: 'grid min-[760px]:grid-cols-2 gap-4') do
          t('join.pricing.extras.addons').each { |addon| render_addon(addon) }
          render_training_addon
        end
      end
    end
  end

  def render_addon(addon)
    div(class: 'flex flex-col bg-cream border-2 border-rules rounded-card p-6') do
      h3(class: 'font-serif font-regular text-[1.5rem] text-foreground mt-0 mb-1.5') { addon[:title] }
      p(class: 'text-[0.98rem] leading-relaxed text-tertiary mt-0 mb-4') { addon[:body] }
      div(class: 'font-serif text-[1.35rem] text-foreground mt-auto') do
        plain t('join.pricing.extras.poa')
        small(class: 'block font-sans text-[0.85rem] font-semibold text-tertiary mt-0.5') do
          t('join.pricing.extras.poa_note')
        end
      end
    end
  end

  def render_training_addon
    training = t('join.pricing.extras.training')
    div(class: 'flex flex-col bg-cream border-2 border-rules rounded-card p-6') do
      h3(class: 'font-serif font-regular text-[1.5rem] text-foreground mt-0 mb-1.5') { training[:title] }
      p(class: 'text-[0.98rem] leading-relaxed text-tertiary mt-0 mb-2') { training[:body] }
      ul(class: 'list-none p-0 mt-auto mb-0') do
        training[:rows].each do |row|
          muted = row[:standard] ? 'text-tertiary' : ''
          li(class: 'flex justify-between items-baseline py-2 border-b border-rules last:border-b-0 text-[0.95rem]') do
            span(class: muted) { row[:label] }
            span(class: "font-serif text-[1.15rem] #{muted}") { row[:amount] }
          end
        end
      end
    end
  end

  # The shared four-step rollout as a vertical timeline: a tan spine down
  # the rail, trimmed to start and end at the first and last circles.
  def render_rollout
    section(class: 'py-10') do
      div(class: 'container-public') do
        h2(class: 'font-serif font-regular text-section text-foreground mt-0 mb-4') { t('join.rollout.heading') }
        div(class: 'max-w-[880px]') do
          t('join.rollout.steps').each_with_index do |step, index|
            render_rollout_step(step, index)
          end
        end
      end
    end
  end

  def render_rollout_step(step, index)
    div(class: 'relative grid grid-cols-[48px_1fr] min-[680px]:grid-cols-[64px_200px_1fr] gap-x-5 min-[680px]:gap-x-9 items-center py-6 ' \
               'before:content-[""] before:absolute before:top-0 before:bottom-0 before:left-[23px] min-[680px]:before:left-[31px] before:w-[2px] before:bg-rules ' \
               'first:before:top-1/2 last:before:bottom-1/2') do
      div(class: 'relative self-stretch row-span-2 min-[680px]:row-span-1 flex justify-center') do
        div(class: 'relative z-1 self-center w-11 h-11 min-[680px]:w-14 min-[680px]:h-14 rounded-full bg-secondary text-secondary-ink grid place-items-center font-serif text-[1.2rem] min-[680px]:text-2xl') do
          plain (index + 1).to_s
        end
      end
      div(class: 'col-start-2 min-[680px]:col-start-auto mb-3 min-[680px]:mb-0 flex justify-start min-[680px]:justify-center') do
        # Width, not max-width: the legacy unlayered img { max-width: 100% }
        # rule outranks layered Tailwind utilities and would undo a cap.
        image_tag(ROLLOUT_ART[index], alt: '', class: 'w-[150px] min-[680px]:w-[190px] h-auto')
      end
      div(class: 'col-start-2 min-[680px]:col-start-auto') do
        h3(class: 'font-serif font-regular text-[1.55rem] text-foreground mt-0 mb-1') { step[:title] }
        p(class: 'text-[1.05rem] leading-relaxed text-tertiary m-0 max-w-[46ch]') { step[:body] }
      end
    end
  end

  # Native details/summary, no JS; the first item starts open.
  def render_faq
    section(class: 'py-10 bg-cream') do
      div(class: 'container-public') do
        h2(class: 'font-serif font-regular text-section text-foreground mt-0 mb-4') { t('join.pricing.faq.heading') }
        div(class: 'max-w-[820px]') do
          t('join.pricing.faq.items').each_with_index do |item, index|
            details(class: 'group border-b-2 border-rules', open: index.zero?) do
              summary(class: 'cursor-pointer list-none py-4 font-serif text-[1.25rem] text-foreground flex justify-between items-center gap-4 ' \
                             '[&::-webkit-details-marker]:hidden after:content-["+"] after:font-sans after:font-bold after:text-2xl ' \
                             'after:text-secondary-strong after:transition-transform group-open:after:rotate-45') do
                item[:question]
              end
              p(class: 'mt-0 pb-4 text-[1.02rem] leading-relaxed text-tertiary max-w-(--width-prose)') { item[:answer] }
            end
          end
        end
      end
    end
  end

  def tier_from?(tier)
    I18n.exists?("join.pricing.tiers.#{tier}.from")
  end
end
