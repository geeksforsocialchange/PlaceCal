# frozen_string_literal: true

# A row that wraps onto the next line when it runs out of room. Layout only: it has no look of its own.
class Components::UI::Cluster < Components::Base
  GAPS = { none: 'gap-x-0', xs: 'gap-x-1', sm: 'gap-x-2', sm_md: 'gap-x-3', md: 'gap-x-4', lg: 'gap-x-6', xl: 'gap-x-8' }.freeze
  ROW_GAPS = { none: 'gap-y-0', xs: 'gap-y-1', sm: 'gap-y-2', sm_md: 'gap-y-3', md: 'gap-y-4', lg: 'gap-y-6', xl: 'gap-y-8' }.freeze
  JUSTIFY = { start: nil, center: 'justify-center', end: 'justify-end', between: 'justify-between' }.freeze
  # With justify_from:, the row starts at the left below that breakpoint and takes justify: from it.
  JUSTIFY_FROM = { xl: { start: nil, center: 'xl:justify-center', end: 'xl:justify-end', between: 'xl:justify-between' } }.freeze
  ALIGN = { center: 'items-center', start: 'items-start', end: 'items-end', baseline: 'items-baseline', stretch: 'items-stretch' }.freeze
  NOWRAP_FROM = { lg: 'lg:flex-nowrap' }.freeze
  TAGS = %i[div ul ol nav section].freeze

  prop :gap, _Union(*GAPS.keys), default: :sm
  # Defaults to the same as gap.
  prop :row_gap, _Nilable(_Union(*ROW_GAPS.keys)), default: nil
  prop :justify, _Union(*JUSTIFY.keys), default: :start
  prop :justify_from, _Nilable(_Union(*JUSTIFY_FROM.keys)), default: nil
  prop :align, _Union(*ALIGN.keys), default: :center
  prop :wrap, _Boolean, default: true
  # Wraps below this breakpoint and stays on one line from it.
  prop :nowrap_from, _Nilable(_Union(*NOWRAP_FROM.keys)), default: nil
  prop :as, _Union(*TAGS), default: :div
  prop :attributes, Hash, :**

  def view_template(&)
    css = ['flex', (@wrap ? 'flex-wrap' : 'flex-nowrap'), NOWRAP_FROM[@nowrap_from], GAPS[@gap], ROW_GAPS[@row_gap || @gap],
           justify_class, ALIGN[@align], ('reset' if %i[ul ol].include?(@as)), @attributes[:class]]
    public_send(@as, class: css.compact.join(' '), **@attributes.except(:class), &)
  end

  private

  def justify_class
    @justify_from ? JUSTIFY_FROM[@justify_from][@justify] : JUSTIFY[@justify]
  end
end
