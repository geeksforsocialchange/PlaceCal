# frozen_string_literal: true

# app/controllers/admin/calendars_controller.rb
module Admin
  class CalendarsController < Admin::ApplicationController
    before_action :set_calendar, only: %i[show edit update destroy import]
    before_action :preselect_partner, only: %i[new create]

    def index
      @calendars = policy_scope(Calendar)
      authorize Calendar

      respond_to do |format|
        format.html { @calendars = @calendars.order(updated_at: :desc, name: :asc) }
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
      @calendar = Calendar.new
      @calendar.place_id = @partner&.id if @partner&.address_id.present?
      @partner_missing_address = @partner.present? && @partner.address_id.blank?
      authorize @calendar
    end

    def edit
      authorize @calendar
      @versions = @calendar.recent_activity
      @partner = @calendar.partner
    end

    def show
      authorize @calendar
    end

    def create
      @calendar = Calendar.new(calendar_params)
      authorize @calendar

      if @calendar.save
        redirect_to edit_admin_calendar_path(@calendar)
        flash[:success] = 'New calendar created and queued for importing. Please check back in a few minutes.'
      else
        flash.now[:danger] = 'Calendar did not save'
        render 'new', status: :unprocessable_content
      end
    end

    def update
      if @calendar.update(calendar_params)
        flash[:success] = 'Calendar successfully updated'
        redirect_to edit_admin_calendar_path(@calendar)
      else
        flash.now[:danger] = 'Calendar did not save'
        render 'edit', status: :unprocessable_content
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
      force_import = true
      @calendar.queue_for_import! force_import

      flash[:success] = 'Calendar added to the import queue'
      redirect_to edit_admin_calendar_path(@calendar)
    end

    # Test a calendar source URL and detect the importer type
    def test_source
      authorize Calendar, :create?

      source = params[:source].to_s.strip

      return render json: { valid: false, error: 'Please enter a URL' } if source.blank?

      return render json: { valid: false, error: 'Please enter a valid URL' } unless Calendar::CALENDAR_REGEX.match?(source)

      # Try to detect the importer
      temp_calendar = Calendar.new(source: source, importer_mode: 'auto')
      begin
        importer = CalendarImporter::CalendarImporter.new(temp_calendar)
        parser = importer.parser

        if parser
          render json: {
            valid: true,
            importer_key: parser::KEY,
            importer_name: parser::NAME
          }
        else
          render json: { valid: false, error: 'Unable to detect calendar format' }
        end
      rescue CalendarImporter::Exceptions::InaccessibleFeed,
             CalendarImporter::Exceptions::UnsupportedFeed => e
        render json: { valid: false, error: e.message }
      rescue StandardError => e
        Rails.logger.error("Calendar test_source error: #{e.message}")
        render json: { valid: false, error: 'Unable to validate this URL' }
      end
    end

    private

    def preselect_partner
      return if params[:partner_id].blank?

      @partner = policy_scope(Partner).find_by(id: params[:partner_id])
    end

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
        :public_contact_email,
        :checksum_updated_at
      )
    end
  end
end
