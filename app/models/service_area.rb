# frozen_string_literal: true

class ServiceArea < ApplicationRecord
  belongs_to :neighbourhood
  belongs_to :partner

  validates :partner, uniqueness: { scope: :neighbourhood }
end
