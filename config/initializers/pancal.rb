# frozen_string_literal: true

# PanCal is the parsing engine behind the calendar importer (gems/pancal).
# It defaults to a null logger; surface its warnings in the Rails log.
PanCal.logger = Rails.logger

# Keep the gem's time zone (used for zoneless feed timestamps and the
# icalendar TZID fallback) in lockstep with the app's
PanCal.default_time_zone = Rails.application.config.time_zone
