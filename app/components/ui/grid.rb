# frozen_string_literal: true

# Equal columns whose count steps up at breakpoints, on the same gap scale as Cluster and Stack. Layout only.
class Components::UI::Grid < Components::Base
  COLS = {
    base: { 1 => 'grid-cols-1', 2 => 'grid-cols-2', 3 => 'grid-cols-3', 4 => 'grid-cols-4' },
    md: { 1 => 'md:grid-cols-1', 2 => 'md:grid-cols-2', 3 => 'md:grid-cols-3', 4 => 'md:grid-cols-4' },
    lg: { 1 => 'lg:grid-cols-1', 2 => 'lg:grid-cols-2', 3 => 'lg:grid-cols-3', 4 => 'lg:grid-cols-4' }
  }.freeze
  GAPS = Components::UI::Stack::GAPS
  TAGS = %i[div ul ol section].freeze

  # Breakpoint to column count, such as { md: 2, lg: 3 }. Without :base, narrow screens get one column.
  prop :cols, _Hash(_Union(*COLS.keys), _Union(1, 2, 3, 4))
  prop :gap, _Union(*GAPS.keys), default: :md
  prop :as, _Union(*TAGS), default: :div
  prop :attributes, Hash, :**

  def view_template(&)
    css = ['grid', GAPS[@gap], *COLS.map { |breakpoint, counts| counts[@cols[breakpoint]] },
           ('reset' if %i[ul ol].include?(@as)), @attributes[:class]]
    public_send(@as, class: css.compact.join(' '), **@attributes.except(:class), &)
  end
end
