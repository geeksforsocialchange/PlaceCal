class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true
end
