# frozen_string_literal: true

class Views::Join::Pricing < Views::Join::Base
  PACKAGE_KEYS = %i[you_run we_run].freeze

  def view_template
    content_for(:title) { t('join.pricing.title') }
    content_for(:description) { t('join.pricing.description') }

    render_hero
    render_packages
    render_compare
    render_includes
    render_extras
    render_faq
    render_cta(heading: t('join.pricing.cta.heading'), body: t('join.pricing.cta.body'), button: t('join.home.cta.button'))
  end

  private

  def render_hero
    section(class: 'bg-secondary py-10') do
      div(class: 'container-public') do
        breadcrumb([t('join.nav.pricing')], on_secondary: true)
        UI::Cluster(gap: :xl, justify: :between, wrap: false) do
          UI::Stack(gap: :sm) do
            UI::Kicker(tone: :strong) { t('join.pricing.eyebrow') }
            h1(class: 'join-headline') { t('join.pricing.title') }
            UI::Text(tone: :strong, measure: :prose) { t('join.pricing.lede') }
          end
          image_tag('home/our_story/collective_ownership.png', alt: '',
                                                               class: 'hidden md:block shrink-0 w-36 xl:w-48 h-auto')
        end
      end
    end
  end

  def render_packages
    section(class: 'py-10') do
      div(class: 'container-public') do
        UI::Stack(gap: :md) do
          UI::Grid(cols: { md: 2 }) do
            PACKAGE_KEYS.each { |key| render_package(key) }
          end
          UI::Text(variant: :lede, tone: :muted) { t('join.pricing.packages.note') }
        end
      end
    end
  end

  def render_package(key)
    UI::Card(tag: :article, padding: :lg) do
      UI::Stack(gap: :sm) do
        UI::Heading(size: :card) { t("join.pricing.packages.#{key}.name") }
        p(class: 'font-serif text-2xl leading-tight text-foreground') { t("join.pricing.packages.#{key}.price") }
        UI::Text(tone: :foreground) { t("join.pricing.packages.#{key}.who") }
        UI::Text(tone: :muted) { t("join.pricing.packages.#{key}.what") }
      end
    end
  end

  # Two value columns fit a phone, so the table stays a table at every width.
  def render_compare
    section(class: 'py-10 bg-cream') do
      div(class: 'container-public') do
        UI::Stack(gap: :md) do
          UI::Heading() { t('join.pricing.compare.heading') }
          div(class: 'max-w-(--width-prose-lg)') do
            table(class: 'w-full border-collapse table-fixed') do
              caption(class: 'sr-only') { t('join.pricing.compare.caption') }
              colgroup do
                col(class: 'w-2/5')
                PACKAGE_KEYS.each { col }
              end
              thead do
                tr do
                  td(class: 'border-b-2 border-foreground')
                  PACKAGE_KEYS.each { |key| render_package_column_header(key) }
                end
              end
              tbody { t('join.pricing.compare.rows').each { |row| render_compare_row(row) } }
            end
          end
        end
      end
    end
  end

  def render_package_column_header(key)
    th(scope: 'col', class: 'text-left align-bottom px-2 md:px-4 pb-3 border-b-2 border-foreground') do
      UI::Kicker(tone: :accent) { t("join.pricing.packages.#{key}.name") }
    end
  end

  def render_compare_row(row)
    tr do
      th(scope: 'row', class: 'text-left align-top font-bold text-foreground text-base px-2 md:px-4 py-3.5 border-b border-rules') do
        row[:label]
      end
      row[:values].each do |value|
        td(class: 'align-top px-2 md:px-4 py-3.5 border-b border-rules text-base leading-normal') do
          case value
          when true then included_mark
          when nil then span(class: 'sr-only') { t('join.pricing.compare.not_included') }
          else plain value
          end
        end
      end
    end
  end

  def included_mark
    svg(width: '20', height: '20', viewBox: '0 0 24 24', fill: 'none',
        stroke: 'currentColor', stroke_width: '2.5', stroke_linecap: 'round', stroke_linejoin: 'round',
        class: 'inline-flex shrink-0 text-secondary-deep', aria_hidden: 'true') do |s|
      s.polyline(points: '20 6 9 17 4 12')
    end
    span(class: 'sr-only') { t('join.pricing.compare.included') }
  end

  def render_includes
    section(class: 'py-10') do
      div(class: 'container-public') do
        UI::Grid(cols: { lg: 2 }, gap: :xl) do
          %i[includes joining].each do |key|
            div do
              UI::Heading(spacing: :md) { t("join.pricing.#{key}.heading") }
              UI::Text(measure: :prose, spacing: :none) { t("join.pricing.#{key}.body") }
            end
          end
        end
      end
    end
  end

  def render_extras
    section(class: 'py-10 bg-cream') do
      div(class: 'container-public') do
        UI::Stack(gap: :lg) do
          UI::Heading() { t('join.pricing.extras.heading') }
          UI::Grid(cols: { md: 2, lg: 3 }) do
            t('join.pricing.extras.items').each do |item|
              UI::Card(padding: :lg) do
                UI::Heading(level: 3, size: :subhead, spacing: :sm) { item[:title] }
                UI::Text(tone: :muted, spacing: :none) { item[:body] }
              end
            end
          end
          div { UI::Button(variant: :join, size: :lg, href: join_demo_path) { t('join.pricing.extras.cta') } }
        end
      end
    end
  end

  # Native details/summary, no JS; the first item starts open.
  def render_faq
    section(class: 'py-10') do
      div(class: 'container-public') do
        UI::Stack(gap: :md) do
          UI::Heading() { t('join.pricing.faq.heading') }
          div(class: 'max-w-(--width-prose-lg)') do
            t('join.pricing.faq.items').each_with_index do |item, index|
              details(class: 'group border-b-2 border-rules', open: index.zero?) do
                summary(class: 'cursor-pointer list-none py-4 pr-1 font-serif text-lg text-foreground flex justify-between items-center gap-4 ' \
                               'details-marker:hidden') do
                  plain item[:question]
                  span(class: 'font-sans font-bold text-2xl text-secondary-strong transition-transform group-open:rotate-45', aria_hidden: 'true') { '+' }
                end
                UI::Text(tone: :muted, measure: :prose, spacing: :xl) { item[:answer] }
              end
            end
          end
        end
      end
    end
  end
end
