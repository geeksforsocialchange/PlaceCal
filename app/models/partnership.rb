# frozen_string_literal: true

class Partnership < Tag
  has_many :partnership_broadcasts, dependent: :destroy
end
