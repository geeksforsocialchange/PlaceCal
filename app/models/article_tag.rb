# frozen_string_literal: true

# == Schema Information
#
# Table name: article_tags
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  article_id :bigint           not null
#  tag_id     :bigint           not null
#
# Indexes
#
#  index_article_tags_article_id_tag_id  (article_id,tag_id) UNIQUE
#  index_article_tags_on_tag_id          (tag_id)
#
# Foreign Keys
#
#  fk_rails_...  (article_id => articles.id)
#  fk_rails_...  (tag_id => tags.id)
#
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
