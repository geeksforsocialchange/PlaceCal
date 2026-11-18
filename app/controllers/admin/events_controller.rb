# frozen_string_literal: true

module Admin
  class EventsController < Admin::ApplicationController
    SIBLINGS_SHOWN = 50

    # Lookup only redirects; show authorizes the event it lands on
    skip_after_action :verify_authorized, only: :lookup

    def show
      event = Event.includes(:calendar, :organiser, :place, :address).find(params[:id])
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
      event = Event.lookup(params[:q])
      return redirect_to admin_event_path(event) if event

      redirect_back_or_to admin_root_path, alert: t('.not_found')
    end
  end
end
