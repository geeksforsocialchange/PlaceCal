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
      @versions = @calendar.recent_activity
    end

    def show
      authorize @calendar
      redirect_to edit_admin_calendar_path(@calendar)
    end

    def create
      @calendar = Calendar.new(calendar_params)
      authorize @calendar

      if @calendar.is_facebook_page
        @calendar.set_fb_page_token(current_user)
      end

      if @calendar.save
        flash[:success] = "Successfully created new calendar"
        redirect_to edit_admin_calendar_path(@calendar)
      else
        flash.now[:danger] = "Calendar did not save"
        render 'new'
      end
    end

    def update
      if @calendar.update(calendar_params)
        flash[:success] = 'Calendar successfully updated'
        redirect_to edit_admin_calendar_path(@calendar)
      else
        flash.now[:danger] = 'Calendar did not save'
        render 'edit'
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

      @calendar.import_events(date)
      flash[:success] = 'The import has completed. See below for details.'

    rescue StandardError => e
      Rails.logger.debug(e)
      Rollbar.error(e)
      flash[:danger] = 'The import ran into an error before completion. Please check error logs for more info.'

    ensure
      redirect_to edit_admin_calendar_path(@calendar)
    end

    def select_page
      authorize Calendar

      facebook_api = Koala::Facebook::API.new(current_user.access_token)
      @pages = facebook_api.get_connections('me', 'accounts', fields: ['id', 'name', 'link'])
      @pages.each { |p| p['has_access'] = has_fb_page_access?(p['id']) }
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


    def has_fb_page_access?(facebook_page_id)
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
