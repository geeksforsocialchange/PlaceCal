# frozen_string_literal: true

# A row that wraps onto the next line when it runs out of room. Layout only: it has no look of its own.
class Components::UI::Cluster < Components::Base
  GAPS = { none: 'gap-x-0', xs: 'gap-x-1', sm: 'gap-x-2', md: 'gap-x-4', lg: 'gap-x-6', xl: 'gap-x-8' }.freeze
  ROW_GAPS = { none: 'gap-y-0', xs: 'gap-y-1', sm: 'gap-y-2', md: 'gap-y-4', lg: 'gap-y-6', xl: 'gap-y-8' }.freeze
  JUSTIFY = { start: nil, center: 'justify-center', end: 'justify-end', between: 'justify-between' }.freeze
  ALIGN = { center: 'items-center', start: 'items-start', baseline: 'items-baseline', stretch: 'items-stretch' }.freeze
  TAGS = %i[div ul ol nav section].freeze

  prop :gap, _Union(*GAPS.keys), default: :sm
  # Defaults to the same as gap.
  prop :row_gap, _Nilable(_Union(*ROW_GAPS.keys)), default: nil
  prop :justify, _Union(*JUSTIFY.keys), default: :start
  prop :align, _Union(*ALIGN.keys), default: :center
  prop :wrap, _Boolean, default: true
  prop :as, _Union(*TAGS), default: :div
  prop :attributes, Hash, :**

  def view_template(&)
    css = ['flex *:my-0', (@wrap ? 'flex-wrap' : 'flex-nowrap'), GAPS[@gap], ROW_GAPS[@row_gap || @gap],
           JUSTIFY[@justify], ALIGN[@align], ('reset' if %i[ul ol].include?(@as)), @attributes[:class]]
    public_send(@as, class: css.compact.join(' '), **@attributes.except(:class), &)
  end
end
