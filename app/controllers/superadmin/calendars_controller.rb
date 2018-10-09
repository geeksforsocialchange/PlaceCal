# frozen_string_literal: true

module Superadmin
  class CalendarsController < Superadmin::ApplicationController
    def show
      super
    end

    def update
      requested_resource.attributes = resource_params
      @refresh_events = requested_resource.source_changed?
      if requested_resource.save
        requested_resource.events.destroy_all if @refresh_events

        redirect_to([namespace, requested_resource],
                    notice: translate_with_resource('update.success'))
      else
        render :edit, locals: {
          page: Administrate::Page::Form.new(dashboard, requested_resource)
        }
      end
    end

    def import
      @calendar = Calendar.find(params[:calendar_id])

      begin
        date = Time.zone.parse(params[:starting_from])

        @calendar.import_events(date)
        flash[:success] = 'The import has completed. See below for details.'
      rescue StandardError => e
        Rails.logger.debug(e)
        Rollbar.error(e)
        flash[:error] = 'The import ran into an error before completion. Please check error logs for more info.'
      end

      redirect_to superadmin_calendar_path(@calendar)
    end

    # To customize the behavior of this controller,
    # you can overwrite any of the RESTful actions. For example:
    #
    # def index
    #   super
    #   @resources = Calendar.
    #     page(params[:page]).
    #     per(10)
    # end

    # Define a custom finder by overriding the `find_resource` method:
    # def find_resource(param)
    #   Calendar.find_by!(slug: param)
    # end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
  end
end
