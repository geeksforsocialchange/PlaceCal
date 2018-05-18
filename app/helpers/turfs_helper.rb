# frozen_string_literal: true

module TurfsHelper
  def options_for_turf_type
    Turf.turf_type.values
  end
end
