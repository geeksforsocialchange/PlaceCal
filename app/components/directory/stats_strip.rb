# frozen_string_literal: true

class Components::Directory::StatsStrip < Components::Directory::Base
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
    div(class: 'flex flex-col bg-home-background border-2 border-rules rounded-card py-3.5 px-4.5') do
      span(class: 'font-serif text-stat leading-none text-foreground') { number_with_delimiter(value) }
      span(class: 'allcaps-label text-tertiary mt-1.5 truncate') { label }
    end
  end

  def number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
