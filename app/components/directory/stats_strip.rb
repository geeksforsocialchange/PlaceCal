# frozen_string_literal: true

class Components::Directory::StatsStrip < Components::Directory::Base
  prop :stats, _Interface(:each)

  def view_template
    section(class: 'py-4 bg-home-background') do
      div(class: 'container-public grid grid-cols-2 lg:grid-cols-4 gap-4') do
        @stats.each do |stat|
          render_bead(stat[:value], stat[:label], stat[:icon])
        end
      end
    end
  end

  private

  def render_bead(value, label, _icon_name = nil)
    # min-w-0 lets the bead shrink below its content in the 2-col mobile grid;
    # wrap-anywhere breaks long single-word labels (e.g. "Neighbourhoods") so the
    # letter-spaced uppercase text can't overflow the cell and widen the page
    div(class: 'flex flex-col bg-home-background border-2 border-rules rounded-card py-3.5 px-4.5 min-w-0') do
      span(class: 'font-serif text-stat leading-none text-foreground') do
        plain ActiveSupport::NumberHelper.number_to_delimited(value)
      end
      span(class: 'allcaps-label text-tertiary mt-1.5 wrap-anywhere') { label }
    end
  end
end
