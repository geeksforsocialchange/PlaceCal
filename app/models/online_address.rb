# frozen_string_literal: true

class OnlineAddress < ApplicationRecord
  # -- Includes / Extends --
  extend Enumerize

  # -- Enums / Enumerize --
  enumerize :link_type,
            in: %i[direct indirect],
            default: :indirect
  # link_type -- managed by enumerize, attribute declaration skipped

  # -- Attributes --
  attribute :url, :string

  # -- Associations --
  has_many :events, dependent: :nullify
end
