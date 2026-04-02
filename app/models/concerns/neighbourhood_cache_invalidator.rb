# frozen_string_literal: true

# Shared callback logic for models that have a direct `neighbourhood`
# association and need to refresh the cached partners_count when that
# association changes.
#
# Used by Address and ServiceArea. Partner has its own implementation
# (refreshes via address.neighbourhood rather than a direct FK).
#
# Usage:
#   class ServiceArea < ApplicationRecord
#     include NeighbourhoodCacheInvalidator
#     after_commit :invalidate_neighbourhood_partners_count!
#   end
#
#   class Address < ApplicationRecord
#     include NeighbourhoodCacheInvalidator
#     after_commit :invalidate_neighbourhood_partners_count!, if: :neighbourhood_id_previously_changed?
#   end
module NeighbourhoodCacheInvalidator
  extend ActiveSupport::Concern

  private

  def invalidate_neighbourhood_partners_count!
    # Refresh current neighbourhood
    neighbourhood&.refresh_partners_count!

    # Refresh old neighbourhood if it changed
    old_neighbourhood_id = previous_changes.dig('neighbourhood_id', 0)
    return unless old_neighbourhood_id

    Neighbourhood.find_by(id: old_neighbourhood_id)&.refresh_partners_count!
  end
end
