# frozen_string_literal: true

# app/controllers/admin/calendars_controller.rb
module Admin
  class CalendarsController < Admin::ApplicationController
    before_action :set_calendar, only: %i[edit update destroy]

    def index
      @calendars = Calendar.all
      authorize current_user
    end

    def show; end

    def new
      @calendar = Calendar.new
      authorize @calendar
    end

    def edit
      authorize @calendar
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
