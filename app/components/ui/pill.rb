# frozen_string_literal: true

class Components::UI::Pill < Components::Base
  BASE = 'inline-flex items-center gap-1.5 rounded-pill no-underline transition-colors'

  VARIANTS = {
    # One option in a set where one is chosen, such as a time period
    tab: 'px-4 py-1.5 text-sm font-bold bg-home-background-3 text-foreground hover:bg-primary',
    tag: 'px-2.5 py-0.5 text-2xs font-bold bg-primary text-foreground hover:bg-primary-light',
    count: 'px-2.5 py-0.5 text-2xs font-bold bg-primary-light text-foreground',
    # For chips on cream cards, such as a partner's categories
    muted: 'px-2.5 py-0.5 text-2xs font-bold bg-home-background-3 text-tertiary',
    # A chip on a dark hero, keeping the hero's text colour
    overlay: 'px-3 py-1 text-sm bg-overlay-light',
    # A partner's or event's neighbourhood
    neighbourhood: 'px-3 max-md:px-1 text-badge max-md:text-badge-sm font-extra-bold uppercase tracking-badge bg-primary text-foreground-dark',
    # A page number or arrow in a paginator, square until the label is wider than it is tall
    page: 'justify-center min-w-9 h-9 px-2 text-sm font-bold bg-home-background-3 text-foreground hover:bg-primary'
  }.freeze

  # Variants without their own selected look take the tab's.
  SELECTED = {
    tab: 'px-4 py-1.5 text-sm font-bold bg-foreground text-background',
    page: 'justify-center min-w-9 h-9 px-2 text-sm font-bold bg-foreground text-background'
  }.freeze

  prop :variant, _Union(*VARIANTS.keys), default: :tab
  prop :selected, _Boolean, default: false
  # Greyed out and not a link, such as the previous arrow on the first page.
  prop :disabled, _Boolean, default: false
  prop :href, _Nilable(String), default: nil
  prop :attributes, Hash, :**

  def view_template(&)
    look = @selected ? SELECTED.fetch(@variant, SELECTED[:tab]) : VARIANTS[@variant]
    css = [BASE, look, ('opacity-30 pointer-events-none' if @disabled), @attributes[:class]].compact.join(' ')
    attributes = @attributes.except(:class)

    if @href && !@selected && !@disabled
      # with-no-sass keeps the legacy SCSS link colour off.
      a(href: @href, class: "with-no-sass #{css}", **attributes, &)
    else
      span(class: css, aria: { current: ('page' if @selected) }, **attributes, &)
    end
  end
end
