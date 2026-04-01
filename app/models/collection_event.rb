# frozen_string_literal: true

class CollectionEvent < ApplicationRecord
  # -- Associations --
  belongs_to :collection
  belongs_to :event
end
