# frozen_string_literal: true

# A list of events as rows, each led by its date, for a partner page or another event's page.
class Components::Sites::EventRows < Components::Base
  theme_scope :event_rows,
              parts: { root: 'The list.', item: 'One event in the list, holding its row.' },
              tokens: %i[]

  prop :events, _Array(_Interface(:summary, :dtstart))
  prop :context_partner, _Nilable(::Partner), default: nil
  prop :show_neighbourhoods, _Boolean, default: false
  prop :badge_zoom_level, _Nilable(String), default: nil

  def view_template
    ol(**part(:root, class: 'reset')) do
      @events.each do |event|
        li(**part(:item, class: 'block')) { Sites::EventRow(event:, context_partner: @context_partner, show_neighbourhoods: @show_neighbourhoods, badge_zoom_level: @badge_zoom_level) }
      end
    end
  end
end
