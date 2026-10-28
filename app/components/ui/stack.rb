# frozen_string_literal: true

# Children one under another, spaced by the gap and never by their own margins, margin utilities included. Layout only.
class Components::UI::Stack < Components::Base
  GAPS = { none: 'gap-0', xs: 'gap-1', sm: 'gap-2', md: 'gap-4', lg: 'gap-6', xl: 'gap-8' }.freeze
  ALIGN = { stretch: nil, start: 'items-start', center: 'items-center' }.freeze
  TAGS = %i[div ul ol section aside].freeze

  prop :gap, _Union(*GAPS.keys), default: :md
  prop :align, _Union(*ALIGN.keys), default: :stretch
  prop :as, _Union(*TAGS), default: :div
  prop :attributes, Hash, :**

  def view_template(&)
    css = ['flex flex-col *:my-0', GAPS[@gap], ALIGN[@align], ('reset' if %i[ul ol].include?(@as)), @attributes[:class]]
    public_send(@as, class: css.compact.join(' '), **@attributes.except(:class), &)
  end
end
