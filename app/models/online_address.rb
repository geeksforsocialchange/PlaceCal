# frozen_string_literal: true

class OnlineAddress < ApplicationRecord
  extend Enumerize

  has_many :events

  enumerize :link_type,
            in: %i[direct indirect],
            default: :indirect
end
