# frozen_string_literal: true

json.array! @places, partial: 'places/place', as: :place
