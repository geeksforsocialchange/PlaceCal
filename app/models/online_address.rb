# frozen_string_literal: true

class OnlineAddress < ApplicationRecord
  has_many :events
end
