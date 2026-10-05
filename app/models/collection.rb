# frozen_string_literal: true

# == Schema Information
#
# Table name: collections
#
#  id          :bigint           not null, primary key
#  description :text
#  image       :string
#  name        :string
#  route       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Collection < ApplicationRecord
  # ==== Includes / Extends ====
  include Permalinkable

  # ==== Attributes ====
  attribute :description, :text
  # image -- managed by CarrierWave, attribute declaration skipped
  attribute :name,        :string
  attribute :route,       :string

  permalink_resource 'collections'

  # ==== Associations ====
  has_and_belongs_to_many :events

  # ==== Uploaders ====
  mount_uploader :image, ImageUploader

  # ==== Instance methods ====

  # @return [ActiveRecord::Relation<Event>] events ordered by start date
  def sorted_events
    events.order(:dtstart).includes(:place)
  end

  # @return [DateTime, nil] earliest event start date in this collection
  def start_date
    sorted_events&.first&.dtstart
  end

  # @return [String] URL path using custom route or fallback to /collections/:id
  def named_route
    route.length.positive? ? "/#{route}" : "/collections/#{id}"
  end
end
