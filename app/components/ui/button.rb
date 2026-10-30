# frozen_string_literal: true

class Components::UI::Button < Components::Base
  # The focus outline is foreground, not current colour, because some variants put cream text on a cream page.
  BASE = 'inline-flex items-center justify-center gap-2 border-2 font-bold no-underline cursor-pointer transition-colors duration-150 focus-visible:outline-foreground'

  VARIANTS = {
    primary: 'bg-primary border-primary text-foreground-dark hover:bg-primary-light hover:border-primary-light',
    dark: 'bg-foreground border-foreground text-background hover:bg-tertiary hover:border-tertiary',
    outline: 'bg-home-background border-primary text-foreground hover:bg-primary hover:text-foreground-dark',
    dark_outline: 'bg-transparent border-foreground text-foreground hover:bg-foreground hover:text-background',
    # Cream fill for coloured panels, e.g. the Our Story call to action.
    light: 'bg-home-background border-home-background text-foreground hover:bg-foreground hover:border-foreground hover:text-background',
    join: 'bg-secondary-strong border-secondary-strong text-background hover:bg-foreground hover:border-foreground',
    # Secondary fill inside a ring, e.g. the local-site home call to action; dark text keeps AA on every colour theme.
    secondary: 'bg-secondary border-background ring-2 ring-secondary text-foreground-dark hover:bg-foreground hover:ring-foreground hover:text-background',
    # Dark fill that turns to the page colour on hover, outlined by a ring outside the border.
    dark_invert: 'bg-foreground border-transparent ring-2 ring-foreground text-background hover:bg-background hover:text-foreground'
  }.freeze

  SIZES = {
    sm: 'px-4 text-sm',
    md: 'px-5 text-detail',
    lg: 'px-6 text-base',
    xl: 'px-8 text-base'
  }.freeze

  PILL_PADDING = { sm: 'py-1.5', md: 'py-2', lg: 'py-3', xl: 'py-3.25' }.freeze

  theme_scope :button, parts: { root: 'The button: an <a> when it has an href, otherwise a <button>.' }, variants: { root: VARIANTS.keys },
                       tokens: %i[--color-primary --color-primary-light --color-foreground --color-foreground-dark --color-background
                                  --color-home-background --color-tertiary --color-secondary --color-secondary-strong
                                  --radius-pill --radius-sm --height-field --text-sm --text-detail --text-base]

  prop :variant, _Union(*VARIANTS.keys)
  prop :size, _Union(*SIZES.keys), default: :md
  # :field squares the corners and matches the height of the filter form controls.
  prop :shape, _Union(:pill, :field), default: :pill
  prop :href, _Nilable(String), default: nil
  prop :type, String, default: 'button'
  prop :attributes, Hash, :**

  def view_template(&)
    attributes = part(:root, variant: @variant, class: css, **@attributes.except(:class))

    if @href
      a(href: @href, **attributes, &)
    else
      button(type: @type, **attributes, &)
    end
  end

  private

  def css
    shape = @shape == :field ? 'h-(--height-field) rounded-sm' : "#{PILL_PADDING[@size]} rounded-pill"
    [BASE, VARIANTS[@variant], SIZES[@size], shape, @attributes[:class]].compact.join(' ')
  end
end
