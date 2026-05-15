# frozen_string_literal: true

# TODO(#3163): Move to app/directory/components/stats_strip.rb
class Components::StatsStrip < Components::Base
  # stats: array of { value:, label: } hashes
  prop :stats, _Interface(:each)

  def view_template
    section(class: 'py-8 bg-home-background border-b-2 border-rules') do
      div(class: 'container-public grid grid-cols-2 lg:grid-cols-4 gap-4') do
        @stats.each do |stat|
          render_bead(stat[:value], stat[:label])
        end
      end
    end
  end

  private

  def render_bead(value, label)
    div(class: 'flex flex-col bg-home-background border-2 border-rules rounded-[1rem] py-3.5 px-4.5') do
      span(class: 'font-serif text-[2rem] leading-none text-foreground') { number_with_delimiter(value) }
      span(class: 'text-[0.7rem] font-extra-bold uppercase tracking-wide text-tertiary mt-1.5') { label }
    end
  end

  def number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
