# frozen_string_literal: true

class Components::UI::Card < Components::Base
  VARIANTS = {
    outlined: 'bg-home-background border-2 border-rules',
    # Sets one card apart from the outlined ones around it, such as the free tier on pricing
    featured: 'bg-cream-warm border-2 border-rules',
    panel: 'bg-home-background-3',
    # Dark text keeps AA on the secondary fill of every colour theme.
    highlight: 'bg-secondary text-foreground-dark'
  }.freeze

  PADDING = { none: nil, sm: 'p-4', md: 'p-5', lg: 'p-6', xl: 'p-8' }.freeze
  TAGS = %i[div article aside section form].freeze

  prop :variant, _Union(*VARIANTS.keys), default: :outlined
  prop :padding, _Union(*PADDING.keys), default: :md
  prop :tag, _Union(*TAGS), default: :div
  prop :href, _Nilable(String), default: nil
  prop :attributes, Hash, :**

  def view_template(&)
    css = ['rounded-card', VARIANTS[@variant], PADDING[@padding], @attributes[:class]].compact.join(' ')
    attributes = @attributes.except(:class)

    if @href
      a(href: @href, class: "no-underline text-foreground transition-all hover:border-secondary-deep motion-safe:hover:-translate-y-0.5 #{css}",
        **attributes, &)
    else
      send(@tag, class: css, **attributes, &)
    end
  end
end
