# frozen_string_literal: true

class ServiceArea < ApplicationRecord
  # -- Associations --
  belongs_to :neighbourhood
  belongs_to :partner

  # -- Validations --
  validates :partner, uniqueness: { scope: :neighbourhood }

  # -- Callbacks --
  after_commit :refresh_neighbourhood_partners_count

  private

  # -- Private methods --
  def refresh_neighbourhood_partners_count
    # Refresh current neighbourhood
    neighbourhood&.refresh_partners_count!

    # Refresh old neighbourhood if it changed
    old_neighbourhood_id = previous_changes.dig('neighbourhood_id', 0)
    return unless old_neighbourhood_id

    Neighbourhood.find_by(id: old_neighbourhood_id)&.refresh_partners_count!
  end
end
