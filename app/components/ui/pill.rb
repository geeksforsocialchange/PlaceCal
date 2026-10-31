# frozen_string_literal: true

class Components::UI::Pill < Components::Base
  BASE = 'inline-flex items-center gap-1.5 no-underline transition-colors'

  VARIANTS = {
    # One option in a set where one is chosen, such as a time period
    tab: 'rounded-pill px-4 py-1.5 text-sm font-bold bg-home-background-3 text-foreground hover:bg-primary hover:text-foreground-dark',
    tag: 'rounded-pill px-2.5 py-0.5 text-2xs font-bold bg-primary text-foreground-dark hover:bg-primary-light',
    count: 'rounded-pill px-2.5 py-0.5 text-2xs font-bold bg-primary-light text-foreground-dark',
    # For chips on cream cards, such as a partner's categories
    muted: 'rounded-pill px-2.5 py-0.5 text-2xs font-bold bg-home-background-3 text-tertiary',
    # A chip on a dark hero, keeping the hero's text colour
    overlay: 'rounded-pill px-3 py-1 text-sm bg-overlay-light text-inherit',
    # A partner's or event's neighbourhood
    neighbourhood: 'rounded-pill px-3 max-md:px-1 text-badge max-md:text-badge-sm font-extra-bold uppercase tracking-badge bg-primary text-foreground-dark',
    # A page number or arrow in a paginator, square until the label is wider than it is tall
    page: 'rounded-pill justify-center min-w-9 h-9 px-2 text-sm font-bold bg-home-background-3 text-foreground hover:bg-primary hover:text-foreground-dark',
    # A letter in an A to Z index, square until the label is wider, such as "All"
    letter: 'rounded-sm justify-center min-w-7 h-7 px-2 text-sm font-bold text-foreground hover:bg-home-background-3',
    # An outlined option in a filter row, such as a region, a day or a time period; it takes the row's text size, line height and resting weight
    segment: 'rounded-pill justify-center whitespace-nowrap border-2 px-4 py-1 bg-background text-foreground border-primary hover:border-foreground'
  }.freeze

  # Variants without their own selected look take the tab's.
  SELECTED = {
    tab: 'rounded-pill px-4 py-1.5 text-sm font-bold bg-foreground text-background',
    page: 'rounded-pill justify-center min-w-9 h-9 px-2 text-sm font-bold bg-foreground text-background',
    letter: 'rounded-sm justify-center min-w-7 h-7 px-2 text-sm font-bold bg-foreground text-background',
    # Dark text on the theme fill keeps AA on every colour theme.
    segment: 'rounded-pill justify-center whitespace-nowrap border-2 px-4 py-1 font-bold bg-primary text-foreground-dark border-primary'
  }.freeze

  # A selected segment stays a link: themes style filter options as `a[aria-current]`.
  LINKED_WHEN_SELECTED = %i[segment].freeze

  theme_scope :pill, parts: { root: 'The pill: a link, or a span when it is selected or disabled. Selected carries aria-current and, as a segment, stays a link.' },
                     variants: { root: VARIANTS.keys },
                     tokens: %i[--radius-pill --radius-sm --color-primary --color-primary-light --color-foreground --color-foreground-dark
                                --color-background --color-home-background-3 --color-tertiary --color-overlay-light
                                --text-sm --text-2xs --text-badge --text-badge-sm --tracking-badge --font-weight-bold --font-weight-extra-bold]

  prop :variant, _Union(*VARIANTS.keys), default: :tab
  prop :selected, _Boolean, default: false
  # The aria-current value when selected: date for a day, true for an option that is neither a page nor a date.
  prop :current, _Union('page', 'date', 'true'), default: 'page'
  # Greyed out and not a link, such as the previous arrow on the first page.
  prop :disabled, _Boolean, default: false
  prop :href, _Nilable(String), default: nil
  prop :attributes, Hash, :**

  def view_template(&)
    look = @selected ? SELECTED.fetch(@variant, SELECTED[:tab]) : VARIANTS[@variant]
    css = [BASE, look, ('opacity-30 pointer-events-none' if @disabled), @attributes[:class]].compact.join(' ')
    attributes = part(:root, variant: @variant, class: css, aria: { current: (@current if @selected) }, **@attributes.except(:class))

    if link?
      a(href: @href, **attributes, &)
    else
      span(**attributes, &)
    end
  end

  private

  def link?
    @href && !@disabled && (!@selected || LINKED_WHEN_SELECTED.include?(@variant))
  end
end
