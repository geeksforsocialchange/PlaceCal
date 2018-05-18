# frozen_string_literal: true

module LoadUtilities
  extend ActiveSupport::Concern

  included do
    def set_turfs
      @turfs = if current_user&.role&.root?
                 Turf.all
               else
                 current_user&.turfs
               end
    end
  end
end
