# frozen_string_literal: true

class NeighbourhoodFilter
  def initialize(events, params)
    @current_neighbourhood = Neighbourhood.find_by(id: params[:neighbourhood])
    @events = events
  end

  def active?
    @current_neighbourhood.present?
  end

  def apply_to(events)
    return events unless active?

    events.transform_values do |event_group|
      event_group.each_with_object([]) do |event, filtered_events|
        filtered_events << event if @current_neighbourhood.id == event.neighbourhood.id
      end
    end
  end

  def neighbourhoods
    all_event_neighbourhoods =
      @events.each_with_object(Set[]) do |event, neighbourhoods|
        neighbourhoods << event.neighbourhood if event.neighbourhood
      end
    all_event_neighbourhoods.to_a.sort_by(&:name)
  end

  def current_neighbourhood?(neighbourhood)
    @current_neighbourhood.present? && (@current_neighbourhood.id == neighbourhood.id)
  end

  def render_filter(view)
    view.render partial: 'events/neighbourhood_filter', locals: { filter: self }
  end
end
