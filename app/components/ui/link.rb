# frozen_string_literal: true

class Components::UI::Link < Components::Base
  VARIANTS = {
    underline: 'underline decoration-primary decoration-2 underline-offset-2 hover:opacity-80',
    quiet: 'no-underline hover:underline hover:decoration-primary',
    action: 'inline-flex items-center gap-1.5 font-bold no-underline hover:underline hover:decoration-primary'
  }.freeze

  # :inherit takes the colour of the surrounding text, e.g. breadcrumbs on a coloured band.
  TONES = { foreground: 'text-foreground', muted: 'text-tertiary', inherit: nil }.freeze

  prop :href, String
  prop :variant, _Union(*VARIANTS.keys), default: :underline
  prop :tone, _Union(*TONES.keys), default: :foreground
  prop :attributes, Hash, :**

  def view_template(&)
    # with-no-sass keeps the legacy SCSS link colour off.
    css = ['with-no-sass', VARIANTS[@variant], TONES[@tone], @attributes[:class]].compact.join(' ')
    a(href: @href, class: css, **@attributes.except(:class), &)
  end
end
