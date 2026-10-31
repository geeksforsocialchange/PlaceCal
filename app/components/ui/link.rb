# frozen_string_literal: true

class Components::UI::Link < Components::Base
  VARIANTS = {
    underline: 'underline decoration-primary decoration-2 underline-offset-2 skip-ink-auto hover:opacity-80',
    quiet: 'no-underline hover:underline hover:decoration-primary decoration-auto underline-offset-auto skip-ink-auto',
    action: 'inline-flex items-center gap-1.5 font-bold no-underline hover:underline hover:decoration-primary decoration-auto underline-offset-auto skip-ink-auto'
  }.freeze

  # :inherit takes the colour of the surrounding text, e.g. breadcrumbs on a coloured band.
  TONES = { foreground: 'text-foreground', muted: 'text-tertiary', inherit: 'text-inherit' }.freeze
  SIZES = { inherit: nil, sm: 'text-sm', detail: 'text-detail', lg: 'text-lg' }.freeze
  # :code is for a URL shown as itself, such as a permalink: small mono that breaks anywhere rather than overflow.
  FONTS = { inherit: nil, serif: 'font-serif', mono: 'font-mono', code: 'font-mono text-sm break-all' }.freeze

  theme_scope :link, parts: { root: 'The link, an <a>.' }, variants: { root: VARIANTS.keys },
                     tokens: %i[--color-primary --color-foreground --color-tertiary --font-weight-bold
                                --text-sm --text-detail --text-lg --font-serif --font-mono]

  prop :href, String
  prop :variant, _Union(*VARIANTS.keys), default: :underline
  prop :tone, _Union(*TONES.keys), default: :foreground
  prop :size, _Union(*SIZES.keys), default: :inherit
  prop :font, _Union(*FONTS.keys), default: :inherit
  prop :attributes, Hash, :**

  # For links another helper renders, such as active_link_to.
  def self.css(variant: :underline, tone: :foreground, size: :inherit, font: :inherit)
    [VARIANTS[variant], TONES[tone], SIZES[size], FONTS[font]].compact.join(' ')
  end

  def view_template(&)
    css = [self.class.css(variant: @variant, tone: @tone, size: @size, font: @font), @attributes[:class]].compact.join(' ')
    a(href: @href, **part(:root, variant: @variant, class: css, **@attributes.except(:class)), &)
  end
end
