# frozen_string_literal: true

# The join pages' 12-column grid: each c.column(span) takes its span from lg up, and stacks below it.
class Components::Join::Columns < Components::Join::Base
  SPANS = { 4 => 'lg:col-span-4', 6 => 'lg:col-span-6', 8 => 'lg:col-span-8' }.freeze
  ROW_GAPS = { md: 'gap-y-10', sm: 'gap-y-3' }.freeze
  ALIGN = { start: 'items-start', center: 'items-center', stretch: nil }.freeze
  TAGS = %i[div ul ol].freeze
  COLUMN_TAGS = %i[div li].freeze

  prop :row_gap, _Union(*ROW_GAPS.keys), default: :md
  prop :align, _Union(*ALIGN.keys), default: :start
  prop :as, _Union(*TAGS), default: :div
  prop :attributes, Hash, :**

  def view_template
    css = ['grid grid-cols-1 lg:grid-cols-12 gap-x-8', ROW_GAPS[@row_gap], ALIGN[@align], ('reset' if %i[ul ol].include?(@as))]
    public_send(@as, class: css.compact.join(' '), **@attributes) { yield(self) }
  end

  # fill: stretches a lone child, such as a card, to the height of the row.
  def column(span, as: :div, fill: false, &)
    public_send(COLUMN_TAGS.include?(as) ? as : :div, class: ['min-w-0', SPANS.fetch(span), ('grid' if fill)].compact.join(' '), &)
  end
end
