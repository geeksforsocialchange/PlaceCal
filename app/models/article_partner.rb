class ArticlePartner < ApplicationRecord
  belongs_to :article
  belongs_to :partner

  validates :article_id, presence: true
  validates :partner_id, presence: true
end
