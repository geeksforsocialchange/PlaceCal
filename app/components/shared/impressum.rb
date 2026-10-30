# frozen_string_literal: true

# Footer small print. The wrapping footer owns the styling.
class Components::Shared::Impressum < Components::Base
  prop :logo, _Boolean, default: true
  # Partner sites print the registered company details as well.
  prop :company_details, _Boolean, default: false

  def view_template
    render_logo if @logo
    if @company_details
      render_company_details
    else
      UI::Cluster(gap: :sm, justify: :between, align: :stretch) do
        span { copyright }
        span do
          plain t('colophon.build')
          whitespace
          UI::Link(href: AppVersion.url, tone: :muted) { AppVersion.label(fallback: 'main') }
        end
      end
    end
  end

  private

  def copyright
    "#{t('colophon.year', year: Time.zone.today.year)} #{t('colophon.copyright')}"
  end

  def render_company_details
    p(class: 'my-2') do
      plain copyright
      br
      plain t('colophon.company')
      br
      plain t('colophon.address')
    end
    p(class: 'my-2') do
      plain t('colophon.build')
      whitespace
      tag.tt { link_to(AppVersion.label(fallback: 'main'), AppVersion.url, class: UI::Link.css(tone: :inherit)) }
    end
  end

  def render_logo
    link_to('https://gfsc.community', class: 'inline-block mb-2') do
      image_tag('gfsc-logo-dark.svg', class: 'h-10 w-auto', alt: t('colophon.gfsc_logo_alt'), width: 144, height: 40)
    end
  end
end
