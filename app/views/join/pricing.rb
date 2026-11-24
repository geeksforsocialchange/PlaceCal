# frozen_string_literal: true

class Views::Join::Pricing < Views::Join::Base
  PACKAGES = %i[you_run we_run].freeze
  EXTRAS = { theme: :app_window, apps: :code, development: :users, translation: :languages }.freeze
  THEME_EXAMPLE_URL = 'https://transdimension.uk'

  def view_template
    content_for(:title) { t('join.pricing.title') }
    content_for(:description) { t('join.pricing.description') }

    render_hero
    render_packages
    render_includes
    render_joining
    render_extras
    render_faq
    render_cta(heading: t('join.pricing.cta.heading'), body: t('join.pricing.cta.body'))
  end

  private

  def render_hero
    Join::Section(band: :salmon) do
      Join::Columns() do |c|
        c.column(8) do
          UI::Stack(gap: :md) do
            UI::Kicker() { t('join.pricing.eyebrow') }
            h1(class: 'join-headline text-foreground-darker') { t('join.pricing.heading') }
            UI::Text(variant: :intro) { t('join.pricing.lede') }
          end
        end
      end
    end
  end

  def render_packages
    Join::Section(aria_label: t('join.pricing.aria_label')) do
      Join::Columns(align: :stretch) do |c|
        PACKAGES.each { |key| c.column(6, fill: true) { render_package(key) } }
      end
    end
  end

  def render_package(key)
    scope = "join.pricing.packages.#{key}"
    UI::Card(tag: :article, variant: :cream, padding: :xl) do
      UI::Stack(gap: :sm_md) do
        UI::Heading(size: :section, tone: :strong, spacing: :none) { t("#{scope}.name") }
        UI::Cluster(gap: :xl, row_gap: :xs, align: :baseline) do
          price(t("#{scope}.setup_price"), t('join.pricing.setup'))
          price(t("#{scope}.monthly_price"), t('join.pricing.monthly'))
        end
        UI::Text(tone: :strong) { strong { t("#{scope}.who") } }
        UI::Text() { t("#{scope}.what") }
        dl(class: 'm-0 mt-2') do
          t("#{scope}.rows").each do |row|
            div(class: 'flex justify-between gap-4 py-3 border-t-2 border-rules') do
              dt(class: 'font-regular') { row[:label] }
              dd(class: 'm-0 font-bold text-foreground-dark text-right') { row[:value] }
            end
          end
        end
      end
    end
  end

  def price(amount, label)
    p(class: 'm-0 font-serif text-subhead leading-tight text-foreground-dark') do
      plain amount
      whitespace
      span(class: 'font-sans font-bold text-detail text-foreground') { label }
    end
  end

  def render_includes
    Join::Section(band: :tint) do
      UI::Stack(gap: :xl) do
        section_heading(t('join.pricing.includes.heading'))
        Join::Columns(as: :ul) do |c|
          t('join.pricing.includes.items').each do |item|
            c.column(4, as: :li) { p(class: 'm-0 pt-5 border-t-4 border-primary font-serif text-xl leading-snug') { item } }
          end
        end
      end
    end
  end

  def render_joining
    Join::Section() do
      Join::Columns() do |c|
        c.column(8) do
          UI::Stack(gap: :md, align: :start) do
            section_heading(t('join.pricing.joining.heading'))
            t('join.pricing.joining.paragraphs').each { |paragraph| UI::Text(measure: :prose_md) { paragraph } }
            UI::Button(variant: :ink_outline, href: "#{apex_url}/partnerships") { t('join.pricing.joining.cta') }
          end
        end
        c.column(4) { Join::Quote(text: t('join.pricing.joining.quote'), by: t('join.pricing.joining.quote_by')) }
      end
    end
  end

  def render_extras
    Join::Section(band: :cream) do
      UI::Stack(gap: :xl) do
        Join::Columns() do |c|
          c.column(8) do
            UI::Stack(gap: :md) do
              section_heading(t('join.pricing.extras.heading'))
              UI::Text() { t('join.pricing.extras.intro') }
            end
          end
        end
        Join::Columns(align: :stretch) do |c|
          EXTRAS.each { |key, icon_name| c.column(6, fill: true) { render_extra(key, icon_name) } }
        end
      end
    end
  end

  def render_extra(key, icon_name)
    UI::Card(padding: :lg) do
      UI::Stack(gap: :sm) do
        span(class: 'text-secondary-strong') { icon(icon_name, size: '8') }
        UI::Heading(level: 3, size: :card, tone: :strong) { t("join.pricing.extras.#{key}.title") }
        UI::Text() { extra_body(key) }
      end
    end
  end

  def extra_body(key)
    return t("join.pricing.extras.#{key}.body") unless key == :theme

    link = view_context.link_to(t('join.pricing.extras.theme.link_text'), THEME_EXAMPLE_URL, class: UI::Link.css)
    raw(t('join.pricing.extras.theme.body_html', link:))
  end

  def render_faq
    Join::Section() do
      Join::Columns() do |c|
        c.column(4) { UI::Stack() { section_heading(t('join.pricing.faq.heading')) } }
        c.column(8) do
          dl(class: 'm-0 flex flex-col gap-7') do
            t('join.pricing.faq.items').each do |item|
              div do
                dt(class: 'font-serif text-xl leading-snug text-foreground-dark') { item[:question] }
                dd(class: 'm-0 mt-1.5 max-w-(--width-prose-md)') { item[:answer] }
              end
            end
          end
        end
      end
    end
  end
end
