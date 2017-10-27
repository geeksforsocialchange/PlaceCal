module Admin
  class CalendarsController < Admin::ApplicationController

    def show
      @events = requested_resource.events
      @recent_activity = PaperTrail::Version.where(item_type: 'Event', item_id: @events.pluck(:id)).where("created_at >= ?", 1.week.ago)
                                            .order(created_at: :desc)
                                            .group_by { |version| version.created_at.to_date }
      super
    end

    def update
      requested_resource.attributes = resource_params
      @refresh_events = requested_resource.source_changed?
      if requested_resource.save
        requested_resource.events.destroy_all if @refresh_events

        redirect_to( [namespace, requested_resource],
                     notice: translate_with_resource('update.success')
                   )
      else
        render :edit, locals: {
          page: Administrate::Page::Form.new(dashboard, requested_resource)
        }
      end
    end

    def import
      @calendar = Calendar.find(params[:calendar_id])

      unless @calendar.import_lock_at
        begin
          date = DateTime.parse(params[:starting_from])

          @calendar.import_events(date)
          flash[:success] = 'The import has completed. See below for details.'
        rescue => e
          Rails.logger.debug(e)
          Rollbar.error(e)
          flash[:error] = 'The import ran into an error before completion. Please check error logs for more info.'
        end
      else
        flash[:alert] = 'An import is already running for this calendar. Please wait unitl it is done and try again.'
      end

      redirect_to admin_calendar_path(@calendar)
    end

    def recent_activity
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
