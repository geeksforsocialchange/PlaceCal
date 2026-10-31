# frozen_string_literal: true

# A figure over its label on a card, such as a count in the directory's stats strip.
class Components::UI::Stat < Components::Base
  prop :value, String
  prop :label, String

  def view_template
    # min-w-0 and wrap-anywhere stop a long letter-spaced label widening a narrow grid cell.
    UI::Card(padding: :sm, class: 'flex flex-col min-w-0') do
      span(class: 'font-serif text-stat leading-none text-foreground') { @value }
      span(class: 'allcaps-label text-tertiary mt-1.5 wrap-anywhere') { @label }
    end
  end
end
