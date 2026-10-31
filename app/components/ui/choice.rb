# frozen_string_literal: true

# A checkbox drawn as a pill-shaped chip; the block renders the checkbox itself.
class Components::UI::Choice < Components::Base
  register_output_helper :icon

  CHIP = 'group relative inline-flex items-center gap-2.5 py-2.5 pr-4.5 pl-3.25 border-2 border-rules-dark rounded-pill bg-background ' \
         'cursor-pointer font-bold text-detail text-foreground select-none transition-colors hover:border-tertiary ' \
         'has-checked:border-foreground has-checked:bg-home-background-3 has-focus-visible:ring-3 has-focus-visible:ring-focus-ring'
  BOX = 'grid place-items-center size-5 shrink-0 border-2 border-rules-dark rounded-check bg-surface transition-colors ' \
        'group-has-checked:bg-foreground group-has-checked:border-foreground'
  TICK = 'text-background opacity-0 scale-60 transition group-has-checked:opacity-100 group-has-checked:scale-100'

  prop :label, String
  # Attributes for the tick box, such as a theming part.
  prop :box_attributes, Hash, default: -> { {} }
  prop :attributes, Hash, :**

  def view_template(&)
    label(class: [CHIP, @attributes[:class]].compact.join(' '), **@attributes.except(:class)) do
      span(class: 'sr-only', &)
      span(class: [BOX, @box_attributes[:class]].compact.join(' '), **@box_attributes.except(:class)) { icon(:check, size: '4', css_class: TICK) }
      plain @label
    end
  end
end
