# frozen_string_literal: true

class Components::Shared::OpeningTime < Components::Base
  theme_scope :opening_time,
              parts: {
                root: 'One day\'s opening hours: the day, then the times.',
                day: 'The day\'s name.'
              },
              tokens: %i[--font-weight-bold]

  prop :day, String
  prop :opens, String
  prop :closes, String

  def view_template
    li(**part(:root, class: 'grid grid-cols-label-value')) do
      span(**part(:day, class: 'font-bold')) { @day }
      whitespace
      span do
        plain @opens
        raw safe(' &ndash; ')
        plain @closes
      end
    end
  end
end
