# frozen_string_literal: true

# app/controllers/admin/calendars_controller.rb
module Admin
  class CalendarsController < Admin::ApplicationController
    before_action :set_calendar, only: %i[show edit update destroy import]

    def index
      @calendars = policy_scope(Calendar)
      authorize Calendar
    end

    def new
      @calendar = Calendar.new
      authorize @calendar
    end

    def edit
      authorize @calendar

      @events = @calendar.events
      @versions = PaperTrail::Version.with_item_keys('Event', @events.pluck(:id)).where('created_at >= ?', 2.weeks.ago)
                                     .or(PaperTrail::Version.destroys.where("item_type = 'Event' AND object @> ? AND created_at >= ?", { calendar_id: @calendar.id }.to_json, 2.weeks.ago))

      @versions = @versions.order(created_at: :desc).group_by { |version| version.created_at.to_date }
    end

    def create
      @calendar = Calendar.new(calendar_params)
      authorize @calendar
      if @calendar.save
        redirect_to admin_calendars_path
      else
        render 'new'
      end
    end

    def update
      authorize @calendar
      if @calendar.update_attributes(calendar_params)
        redirect_to admin_calendars_path
      else
        render 'edit'
      end
    end

    def destroy
      @calendar.destroy
      respond_to do |format|
        format.html { redirect_to admin_calendars_url, notice: 'Calendar was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    def import
      authorize @calendar, :import?

      begin
        date = DateTime.parse(params[:starting_from])

        @calendar.import_events(date)
        flash[:success] = 'The import has completed. See below for details.'
      rescue StandardError => e
        Rails.logger.debug(e)
        Rollbar.error(e)
        flash[:error] = 'The import ran into an error before completion. Please check error logs for more info.'
      end

      redirect_to edit_admin_calendar_path(@calendar)
    end

    private

    def set_calendar
      @calendar = Calendar.find(params[:id])
    end

    def calendar_params
      params.require(:calendar).permit(
        :id,
        :name,
        :source,
        :type,
        :strategy,
        :address_id,
        :strategy,
        :partner_id,
        :footer
      )
    end
  end
end
