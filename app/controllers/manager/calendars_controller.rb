module Manager
  class CalendarsController < ApplicationController
    before_action :set_calendar, except: [:index]

    def index
      @calendars = policy_scope(Calendar)
    end

    def show
      authorize @calendar, :show?

      @events = @calendar.events
      @versions = PaperTrail::Version.with_item_keys('Event', @events.pluck(:id)).where("created_at >= ?", 2.weeks.ago)
        .or(PaperTrail::Version.destroys.where("item_type = 'Event' AND object @> ? AND created_at >= ?", { calendar_id: @calendar.id }.to_json, 2.weeks.ago ))

      @versions = @versions.order(created_at: :desc).group_by { |version| version.created_at.to_date }

    end

    private

    def set_calendar
      @calendar = Calendar.find(params[:id])
    end
  end
end
