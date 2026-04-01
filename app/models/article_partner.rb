# frozen_string_literal: true

class ArticlePartner < ApplicationRecord
  # -- Associations --
  belongs_to :article
  belongs_to :partner

  # -- Validations --
  validates :partner_id,
            uniqueness: {
              scope: :article_id,
              message: 'Article cannot be assigned more than once to a partner'
            }
end
