# frozen_string_literal: true

class Components::OpeningTimes < Components::Base
  prop :times, Array

  def view_template
    ul(class: 'opening_times reset') do
      @times.each do |slot|
        li { safe(slot) }
      end
    end
  end
end
