# frozen_string_literal: true

module Admin
  class PagesController < Admin::ApplicationController
    def home
      @partners = policy_scope(Partner).order(updated_at: :desc).limit(6)
      @sites = policy_scope([:dashboard, Site]).order(:name)
      @errored_calendars = policy_scope(Calendar).where(is_working: false).order(last_import_at: :desc)
    end
  end
end
