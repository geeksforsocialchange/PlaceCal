# frozen_string_literal: true

# == Schema Information
#
# Table name: article_partners
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  article_id :bigint           not null
#  partner_id :bigint           not null
#
# Indexes
#
#  index_article_partners_on_article_id_and_partner_id  (article_id,partner_id) UNIQUE
#  index_article_partners_on_partner_id                 (partner_id)
#
# Foreign Keys
#
#  fk_rails_...  (article_id => articles.id)
#  fk_rails_...  (partner_id => partners.id)
#
class ArticlePartner < ApplicationRecord
  # ==== Associations ====
  belongs_to :article
  belongs_to :partner

  # ==== Validations ====
  validates :partner_id,
            uniqueness: {
              scope: :article_id,
              message: 'Article cannot be assigned more than once to a partner'
            }
end
