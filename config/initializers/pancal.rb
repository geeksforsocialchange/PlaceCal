# frozen_string_literal: true

# PanCal is the parsing engine behind the calendar importer (gems/pancal).
# It defaults to a null logger; surface its warnings in the Rails log.
PanCal.logger = Rails.logger
