# frozen_string_literal: true

class ArticleTag < ApplicationRecord
  # ==== Associations ====
  belongs_to :article
  belongs_to :tag

  # ==== Validations ====
  validates :tag_id,
            uniqueness: {
              scope: :article_id,
              message: 'Article cannot be assigned more than once to a Tag'
            }
end
