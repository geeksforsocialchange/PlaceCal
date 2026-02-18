# frozen_string_literal: true

module Admin
  class PagesController < Admin::ApplicationController
    before_action :require_root_user, only: [:icons]

    def home
      @user = current_user
      @sites = policy_scope([:dashboard, Site]).order(:name)

      partners_scope = policy_scope(Partner)
      calendars_scope = policy_scope(Calendar)

      @partners = partners_scope.order(updated_at: :desc).limit(6)
      @calendars = calendars_scope.order(updated_at: :desc).limit(6)
      @users = policy_scope(User).order(updated_at: :desc).limit(6)

      # Calendar states for action items
      @errored_calendars = calendars_scope.where(calendar_state: :error).order(last_import_at: :desc).limit(5)
      @bad_source_calendars = calendars_scope.where(calendar_state: :bad_source).order(last_import_at: :desc).limit(5)

      # Recent/upcoming events from user's partners (subquery instead of pluck)
      partner_ids_subquery = partners_scope.select(:id)
      @upcoming_events = Event.where(partner_id: partner_ids_subquery).upcoming.order(:dtstart).limit(8)

      # Stats
      @total_partners = partners_scope.count
      @total_calendars = calendars_scope.count
      @total_events_this_week = Event.where(partner_id: partner_ids_subquery).where(dtstart: Time.current.all_week).count

      # Calendar state counts - single grouped query instead of 4 separate queries
      state_counts = calendars_scope.group(:calendar_state).count
      @working_calendars_count = state_counts['idle'] || 0
      @processing_calendars_count = (state_counts['in_queue'] || 0) + (state_counts['in_worker'] || 0)
      @errored_calendars_count = state_counts['error'] || 0
      @bad_source_calendars_count = state_counts['bad_source'] || 0
      @problem_calendars_count = @errored_calendars_count + @bad_source_calendars_count

      # User's partnerships (tags they manage)
      @user_partnerships = current_user.partnerships.includes(:partners).order(:name)
    end

    def icons
      @icons = SvgIconsHelper::ICONS
    end

    private

    def require_root_user
      return if current_user&.root?

      flash[:error] = 'You need to be a root admin to access this page.'
      redirect_to admin_root_path
    end
  end
end
