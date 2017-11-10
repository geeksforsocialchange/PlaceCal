class CollectionEvent < ApplicationRecord
  belongs_to :collection
  belongs_to :event
end
