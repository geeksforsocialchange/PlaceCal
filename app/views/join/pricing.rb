# frozen_string_literal: true

# The public price list (#3163), a simplified version of the July 2026
# business plan: free listings for groups, tiered one-off setup, a monthly
# service fee scaled by group count, and a no-prices pointer at training and
# bespoke onboarding. Training prices and self-serve signup are deliberately
# withheld until those offers are settled.
class Views::Join::Pricing < Views::Join::Base
  # GFSC's own listing on the directory carries the monthly drop-in events,
  # so the free tier can point at live dates without hardcoding any. This is
  # the production slug; it won't resolve against a development database.
  DROP_INS_PATH = '/partners/geeks-for-social-change'

  SETUP_BANDS = %i[community organisation institution].freeze

  def view_template
    content_for(:title) { t('join.pricing.title') }

    section(class: 'py-10') do
      div(class: 'container-public') do
        breadcrumb([t('join.nav.pricing')])
        render_header
        render_free_banner
        render_setup
        render_service
        render_extras
        p(class: 'text-center text-detail text-tertiary mt-8 mb-0') { t('join.pricing.footnote') }
      end
    end
  end

  private

  def render_header
    div(class: 'text-center mb-8') do
      h1(class: 'join-headline m-0 mb-2') { t('join.pricing.title') }
      p(class: 'text-base text-tertiary leading-relaxed max-w-(--width-prose-md) mx-auto m-0') { t('join.pricing.lede') }
    end
  end

  def render_free_banner
    div(class: 'bg-secondary text-secondary-ink rounded-card p-6 md:p-8 text-center mb-12') do
      h2(class: 'font-serif font-regular text-section m-0 mb-2') { t('join.pricing.free.heading') }
      p(class: 'text-detail leading-relaxed max-w-(--width-prose) mx-auto mt-0 mb-4') { t('join.pricing.free.body') }
      a(href: apex_url(DROP_INS_PATH),
        class: 'with-no-sass font-bold text-secondary-ink underline hover:no-underline') do
        t('join.pricing.free.cta')
      end
    end
  end

  def render_setup
    section_intro(kicker: t('join.pricing.setup.kicker'),
                  heading: t('join.pricing.setup.heading'),
                  lede: t('join.pricing.setup.lede'))
    div(class: 'grid md:grid-cols-3 gap-4 items-stretch mb-4') do
      SETUP_BANDS.each { |band| render_band_card(band) }
    end
    render_setup_includes
  end

  def render_band_card(band)
    div(class: 'bg-home-background rounded-card p-6 border-2 border-rules') do
      h3(class: 'font-serif font-regular text-card text-foreground m-0') { t("join.pricing.setup.bands.#{band}.name") }
      div(class: 'font-serif text-[2.4rem] leading-none text-foreground mt-3 mb-1') { t("join.pricing.setup.bands.#{band}.price") }
      div(class: 'allcaps-label text-tertiary mb-3') { t('join.pricing.setup.one_off') }
      p(class: 'text-sm text-tertiary leading-normal m-0') { t("join.pricing.setup.bands.#{band}.blurb") }
    end
  end

  def render_setup_includes
    div(class: 'bg-home-background rounded-card p-6 border-2 border-rules mb-12') do
      h3(class: 'allcaps-label text-tertiary mt-0 mb-3') { t('join.pricing.setup.includes_heading') }
      ul(class: 'list-none p-0 m-0 grid md:grid-cols-2 gap-x-8') do
        t('join.pricing.setup.items').each do |item|
          li(class: 'py-1.5 border-b border-rules text-detail flex gap-2 items-start') do
            span(class: 'text-secondary-deep mt-0.5') { icon(:check, size: '4') }
            span { item }
          end
        end
      end
    end
  end

  def render_service
    section_intro(kicker: t('join.pricing.service.kicker'),
                  heading: t('join.pricing.service.heading'),
                  lede: t('join.pricing.service.lede'))
    table(class: 'w-full max-w-(--width-prose-md) border-collapse mb-12') do
      caption(class: 'sr-only') { t('join.pricing.service.caption') }
      thead do
        tr do
          th(scope: 'col', class: 'text-left allcaps-label text-tertiary pb-2') { t('join.pricing.service.groups_header') }
          th(scope: 'col', class: 'text-right allcaps-label text-tertiary pb-2') { t('join.pricing.service.price_header') }
        end
      end
      tbody do
        t('join.pricing.service.rows').each do |row|
          tr(class: 'border-t-2 border-rules') do
            td(class: 'py-2.5 text-detail') { row[:groups] }
            td(class: 'py-2.5 text-detail text-right font-bold') { row[:price] }
          end
        end
      end
    end
  end

  def render_extras
    div(class: 'bg-home-background rounded-card p-6 md:p-8 text-center border-2 border-rules') do
      h2(class: 'font-serif font-regular text-section text-foreground mt-0 mb-2') { t('join.pricing.extras.heading') }
      p(class: 'text-detail text-tertiary leading-relaxed max-w-(--width-prose) mx-auto mt-0 mb-4') { t('join.pricing.extras.body') }
      a(href: join_demo_path, class: 'btn-join') { t('join.pricing.extras.cta') }
    end
  end
end
