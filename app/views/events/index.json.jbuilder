# frozen_string_literal: true

json.array! @events, partial: 'events/event', as: :event
