# frozen_string_literal: true

class ArticlePartner < ApplicationRecord
  belongs_to :article
  belongs_to :partner

  validates :partner_id,
            uniqueness: {
              scope: :article_id,
              message: 'Article cannot be assigned more than once to a partner'
            }
end
