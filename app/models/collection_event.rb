# frozen_string_literal: true

class CollectionEvent < ApplicationRecord
  belongs_to :collection
  belongs_to :event
end
