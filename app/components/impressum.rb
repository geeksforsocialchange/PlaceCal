# frozen_string_literal: true

# The shared footer small print: GFSC's legal details and the running build
# version, identical on partner sites, the directory, and the join site.
# Wrapping footers own the layout and typography; this emits classless <p>s.
class Components::Impressum < Components::Base
  # Partner-site footers already show the GFSC logo among the global
  # supporters, so they turn the impressum's own logo off.
  prop :logo, _Boolean, default: true

  def view_template
    render_logo if @logo
    p do
      plain "#{t('colophon.year', year: Time.zone.today.year)} #{t('colophon.copyright')}"
      br
      plain t('colophon.company')
      br
      plain t('colophon.address')
    end
    p do
      plain "#{t('colophon.build')} "
      tag.tt do
        link_to(AppVersion.label(fallback: 'main'), AppVersion.url, class: 'text-inherit underline hover:decoration-primary')
      end
    end
  end

  private

  def render_logo
    link_to('https://gfsc.community', class: 'inline-block mb-2') do
      image_tag('gfsc-logo-dark.svg', class: 'h-10 w-auto', alt: t('colophon.gfsc_logo_alt'), width: 144, height: 40)
    end
  end
end
