class ArticleTag < ApplicationRecord
  belongs_to :article
  belongs_to :tag

  validates :tag_id,
            uniqueness: {
              scope: :article_id,
              message: "Article cannot be assigned more than once to a Tag"
            }
end
