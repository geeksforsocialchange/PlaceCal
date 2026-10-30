# frozen_string_literal: true

class Components::Shared::OpeningTime < Components::Base
  prop :day, String
  prop :opens, String
  prop :closes, String

  def view_template
    li(class: 'grid grid-cols-label-value') do
      span(class: 'opening_times--day font-bold') { @day }
      whitespace
      span(class: 'opening_times--time') do
        plain @opens
        raw safe(' &ndash; ')
        plain @closes
      end
    end
  end
end
