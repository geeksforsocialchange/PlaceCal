# frozen_string_literal: true

class Collection < ApplicationRecord
  has_and_belongs_to_many :events

  mount_uploader :image, ImageUploader

  # Sort associated events by start date
  def sorted_events
    events.order(:dtstart).includes(:place)
  end

  # The first date in this time sequence
  def start_date
    sorted_events&.first&.dtstart
  end

  def permalink
    "https://placecal.org/collections/#{id}"
  end

  def named_route
    route.length.positive? ? "/#{route}" : "/collections/#{id}"
  end
end
