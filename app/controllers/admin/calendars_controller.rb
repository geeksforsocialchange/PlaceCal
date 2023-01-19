# frozen_string_literal: true

# app/controllers/admin/calendars_controller.rb
module Admin
  class CalendarsController < Admin::ApplicationController
    before_action :set_calendar, only: %i[show edit update destroy import]

    def index
      @calendars = policy_scope(Calendar).order(updated_at: :desc).order(:name)
      authorize Calendar

      respond_to do |format|
        format.html
        format.json do
          render json: CalendarDatatable.new(
            params,
            view_context: view_context,
            calendars: @calendars
          )
        end
      end
    end

    def new
      if params[:partner_id]
        # TODO: better calendar-to-user scoping
        # @partner = current_user.partners.where(id: params[:partner_id]).first
        @partner = policy_scope(Partner).where(id: params[:partner_id]).first
      end
      @calendar = Calendar.new
      authorize @calendar
    end

    def edit
      @versions = @calendar.recent_activity
      @partner = @calendar.partner
    end

    def show
      authorize @calendar
    end

    def create
      @calendar = Calendar.new(calendar_params)
      authorize @calendar

      if @calendar.save!
        flash[:success] = 'Successfully created new calendar'
        redirect_to edit_admin_calendar_path(@calendar)
      else
        flash.now[:danger] = 'Calendar did not save'
        render 'new', status: :unprocessable_entity
      end
    end

    def update
      if @calendar.update(calendar_params)
        flash[:success] = 'Calendar successfully updated'
        redirect_to edit_admin_calendar_path(@calendar)
      else
        flash.now[:danger] = 'Calendar did not save'
        render 'edit', status: :unprocessable_entity
      end
    end

    def destroy
      authorize @calendar
      @calendar.destroy
      respond_to do |format|
        format.html do
          flash[:success] = 'Calendar was successfully deleted.'
          redirect_to admin_calendars_url
        end

        format.json { head :no_content }
      end
    end

    def import
      date = Time.zone.parse(params[:starting_from])
      force_import = true
      # CalendarImporterJob.perform_now @calendar.id, date, force_import
      @calendar.queue_for_import! force_import, date

      flash[:success] = 'Calendar added to the import queue'
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
        :strategy,
        :address_id,
        :strategy,
        :partner_id,
        :place_id,
        :importer_mode,
        :public_contact_name,
        :public_contact_phone,
        :public_contact_email
      )
    end
  end
end
