# frozen_string_literal: true

class Article < ApplicationRecord
  validates :title, :body, presence: true
end
