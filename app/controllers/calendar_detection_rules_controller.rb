# frozen_string_literal: true

# Public, unauthenticated JSON export of the calendar parsers' URL detection
# rules, consumed by the PlaceCal browser extension. Lives under /api/ so the
# existing CORS (config/application.rb) and rate-limit rules apply.
class CalendarDetectionRulesController < ApplicationController
  skip_before_action :set_supporters
  skip_before_action :set_navigation

  def show
    payload = CalendarDetectionRules.as_json
    expires_in 6.hours, public: true
    render json: payload if stale?(etag: payload)
  end
end
