# frozen_string_literal: true

json.array! @calendars, partial: 'calendars/calendar', as: :calendar
