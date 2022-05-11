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
        format.json {
          render json: CalendarDatatable.new(
            params,
            view_context: view_context,
            calendars: @calendars
          )
        }
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

      @calendar.set_fb_page_token(current_user) if @calendar.is_facebook_page

      if @calendar.save
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

      flash[:success] = 'The calendar will be imported in a few minutes.'
      redirect_to edit_admin_calendar_path(@calendar)
    end

    def select_page
      authorize Calendar

      facebook_api = Koala::Facebook::API.new(current_user.access_token)
      @pages = facebook_api.get_connections('me', 'accounts', fields: %w[id name link])
      @pages.each { |p| p['has_access'] = fb_page_access?(p['id']) }
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
        :is_facebook_page,
        :facebook_page_id,
        :is_working,
        :public_contact_name,
        :public_contact_phone,
        :public_contact_email,
        :partnership_contact_name,
        :partnership_contact_phone,
        :partnership_contact_email
      )
    end

    def fb_page_access?(facebook_page_id)
      graph = Koala::Facebook::API.new(current_user.access_token)
      token = graph.get_page_access_token(facebook_page_id)
      token.present?
    rescue StandardError => e
      Rails.logger.debug(e)
      Rollbar.error(e)
      return false
    end
  end
end
