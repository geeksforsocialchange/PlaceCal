# frozen_string_literal: true

# A short label, such as a step number or initials, centred in a circle.
class Components::UI::CircleBadge < Components::Base
  SIZES = { sm: 'size-11 text-lg', md: 'size-13 text-subhead', lg: 'size-14 text-2xl' }.freeze
  MD_SIZES = { sm: 'md:size-11 md:text-lg', md: 'md:size-13 md:text-subhead', lg: 'md:size-14 md:text-2xl' }.freeze
  TONES = {
    secondary: 'bg-secondary text-foreground-dark',
    background: 'bg-home-background text-foreground',
    muted: 'bg-home-background-3 text-foreground'
  }.freeze

  prop :size, _Union(*SIZES.keys), default: :sm
  # The size from the md breakpoint up, when it differs.
  prop :md_size, _Nilable(_Union(*MD_SIZES.keys)), default: nil
  prop :tone, _Union(*TONES.keys), default: :muted
  prop :attributes, Hash, :**

  def view_template(&)
    css = ['grid place-items-center shrink-0 rounded-full font-serif', SIZES[@size], MD_SIZES[@md_size], TONES[@tone],
           @attributes[:class]]
    div(class: css.compact.join(' '), **@attributes.except(:class), &)
  end
end
