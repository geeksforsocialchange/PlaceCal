# frozen_string_literal: true

# app/controllers/admin/calendars_controller.rb
module Admin
  class CalendarsController < Admin::ApplicationController
    before_action :set_calendar, only: %i[show edit update destroy import import_status]
    before_action :preselect_partner, only: %i[new create]

    def index
      @calendars = policy_scope(Calendar)
      authorize Calendar

      respond_to do |format|
        format.html do
          @calendars = @calendars.order(updated_at: :desc, name: :asc)
          render Views::Admin::Calendars::Index.new(
            calendars: @calendars,
            partner_options: build_partner_options,
            importer_options: build_importer_options
          )
        end
        format.json do
          render json: CalendarDatatable.new(
            params,
            view_context:,
            calendars: @calendars
          )
        end
      end
    end

    def new
      @calendar = Calendar.new
      @calendar.place_id = @partner&.id if @partner&.address_id.present?
      authorize @calendar
      render Views::Admin::Calendars::New.new(
        calendar: @calendar,
        partner: @partner
      )
    end

    # Open to anyone who can add a calendar, since it helps them pick a source
    def sources
      authorize Calendar, :new?
      render Views::Admin::Calendars::Sources.new(parsers: CalendarImporter::CalendarImporter.public_parsers.sort_by { it::NAME })
    end

    def edit
      authorize @calendar
      @partner = @calendar.organiser
      render Views::Admin::Calendars::Edit.new(calendar: @calendar)
    end

    def show
      authorize @calendar
      render Views::Admin::Calendars::Show.new(calendar: @calendar)
    end

    def create
      @calendar = Calendar.new(calendar_params)
      authorize @calendar

      if @calendar.save
        flash[:success] = t('admin.calendars.flash.created')
        redirect_to edit_admin_calendar_path(@calendar)
      else
        flash.now[:danger] = t('admin.calendars.flash.not_saved')
        render Views::Admin::Calendars::New.new(
          calendar: @calendar,
          partner: @partner
        ), status: :unprocessable_content
      end
    end

    def update
      authorize @calendar
      @calendar.assign_attributes(calendar_params)
      authorize @calendar
      feed_changed = @calendar.feed_changed?

      if @calendar.save
        queued = feed_changed && @calendar.queue_for_import!(true)
        flash[:success] = t(queued ? 'admin.calendars.flash.updated_and_queued' : 'admin.calendars.flash.updated')
        redirect_to edit_admin_calendar_path(@calendar)
      else
        flash.now[:danger] = t('admin.calendars.flash.not_saved')
        render Views::Admin::Calendars::Edit.new(calendar: @calendar), status: :unprocessable_content
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
      authorize @calendar
      force_import = true
      @calendar.queue_for_import! force_import

      flash[:success] = t('admin.calendars.flash.queued')
      redirect_to edit_admin_calendar_path(@calendar)
    end

    def import_status
      authorize @calendar, :show?
      render Views::Admin::Calendars::ImporterOverview.new(calendar: @calendar), layout: false
    end

    # Test a calendar source URL and detect the importer type
    def test_source
      authorize Calendar, :create?

      source = params[:source].to_s.strip

      return render json: { valid: false, error: t('admin.calendars.wizard.source.blank') } if source.blank?

      return render json: { valid: false, error: t('admin.calendars.wizard.source.invalid') } unless Validation::CALENDAR_URL_REGEX.match?(source)

      # Try to detect the importer
      temp_calendar = Calendar.new(source:, importer_mode: 'auto')
      begin
        importer = CalendarImporter::CalendarImporter.new(temp_calendar)
        importer.check_source!
        parser = importer.parser

        if parser
          response = {
            valid: true,
            importer_key: parser::KEY,
            importer_name: parser::NAME
          }

          # API-based parsers need an API key rather than fetching this URL
          if parser.requires_api_token?
            response[:warning] = true
            response[:warning_message] = t('admin.calendars.wizard.source.api_importer_warning', name: parser::NAME)
          end

          render json: response
        else
          render json: { valid: false, error: t('admin.calendars.wizard.source.unsupported') }
        end
      rescue CalendarImporter::Exceptions::InaccessibleFeed => e
        render json: { valid: false, error: e.message }
      rescue CalendarImporter::Exceptions::UnsupportedFeed
        # URL is reachable but format couldn't be auto-detected
        # Allow user to manually select
        render json: { valid: false, needs_manual_selection: true }
      rescue StandardError => e
        Rails.logger.error("Calendar test_source error: #{e.message}")
        render json: { valid: false, error: t('admin.calendars.wizard.source.error') }
      end
    end

    private

    def build_partner_options
      partner_ids_with_calendars = Calendar.distinct.pluck(:organiser_id).compact
      Partner.where(id: partner_ids_with_calendars).order(:name).map do |p|
        { value: p.id.to_s, label: p.name.truncate(40) }
      end
    end

    def build_importer_options
      [{ value: 'pending', label: I18n.t('admin.calendars.importer.pending') }] +
        Calendar.distinct.pluck(:importer_used).compact.compact_blank.sort.map do |i|
          parser = CalendarImporter::CalendarImporter.parser_for_key(i)
          { value: i, label: parser ? parser::NAME : i.titleize }
        end
    end

    def preselect_partner
      return if params[:partner_id].blank?

      @partner = policy_scope(Partner).find_by(id: params[:partner_id])
    end

    def set_calendar
      @calendar = Calendar.find(params[:id])
    end

    def calendar_params
      params.require(:calendar).permit(
        :name,
        :source,
        :strategy,
        :organiser_id,
        :place_id,
        :importer_mode,
        :api_token,
        :public_contact_name,
        :public_contact_phone,
        :public_contact_email
      )
    end
  end
end
