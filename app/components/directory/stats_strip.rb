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
    UI::Stat(value: ActiveSupport::NumberHelper.number_to_delimited(value), label:)
  end
end
