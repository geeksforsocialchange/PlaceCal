# frozen_string_literal: true

module Admin
  class EventsController < Admin::ApplicationController
    SIBLINGS_SHOWN = 50

    def show
      event = Event.includes(:calendar, :organiser, :place, :address, :online_address).find(params[:id])
      authorize event

      siblings = event.siblings
      upcoming = siblings.upcoming
      render Views::Admin::Events::Show.new(
        event:,
        upcoming_siblings: upcoming.includes(:address, :organiser).order(:dtstart).limit(SIBLINGS_SHOWN).to_a,
        upcoming_siblings_count: upcoming.count,
        siblings_count: siblings.count
      )
    end

    def lookup
      authorize Event, :show?
      query = params[:q].to_s.strip
      event = Event.lookup(query) if query.present?
      return redirect_to admin_event_path(event) if event

      render Views::Admin::Events::Lookup.new(query:, not_found: query.present?)
    end
  end
end
