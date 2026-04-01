# frozen_string_literal: true

class Collection < ApplicationRecord
  # -- Includes / Extends --
  include Permalinkable

  # -- Attributes --
  attribute :name,        :string
  attribute :description, :text
  attribute :route,       :string
  # image -- managed by CarrierWave, attribute declaration skipped

  permalink_resource 'collections'

  # -- Associations --
  has_and_belongs_to_many :events

  # -- Uploaders --
  mount_uploader :image, ImageUploader

  # -- Instance methods --
  # Sort associated events by start date
  def sorted_events
    events.order(:dtstart).includes(:place)
  end

  # The first date in this time sequence
  def start_date
    sorted_events&.first&.dtstart
  end

  def named_route
    route.length.positive? ? "/#{route}" : "/collections/#{id}"
  end
end
