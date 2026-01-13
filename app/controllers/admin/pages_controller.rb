# frozen_string_literal: true

module Admin
  class PagesController < Admin::ApplicationController
    def home
      @user = current_user
      @sites = policy_scope([:dashboard, Site]).order(:name)
      @partners = policy_scope(Partner).order(updated_at: :desc).limit(6)

      # Calendar states for action items
      @errored_calendars = policy_scope(Calendar).where(calendar_state: :error).order(last_import_at: :desc).limit(5)
      @bad_source_calendars = policy_scope(Calendar).where(calendar_state: :bad_source).order(last_import_at: :desc).limit(5)

      # Recent/upcoming events from user's partners
      partner_ids = policy_scope(Partner).pluck(:id)
      @upcoming_events = Event.where(partner_id: partner_ids).upcoming.order(:dtstart).limit(8)

      # Stats
      @total_partners = policy_scope(Partner).count
      @total_calendars = policy_scope(Calendar).count
      @total_events_this_week = Event.where(partner_id: partner_ids).where(dtstart: Time.current.all_week).count

      # Calendar state counts
      @working_calendars_count = policy_scope(Calendar).where(calendar_state: :idle).count
      @processing_calendars_count = policy_scope(Calendar).where(calendar_state: %i[in_queue in_worker]).count
      @errored_calendars_count = policy_scope(Calendar).where(calendar_state: :error).count
      @bad_source_calendars_count = policy_scope(Calendar).where(calendar_state: :bad_source).count
      @problem_calendars_count = @errored_calendars_count + @bad_source_calendars_count

      # User's partnerships (tags they manage)
      @user_partnerships = current_user.partnerships.includes(:partners).order(:name)
    end
  end
end
