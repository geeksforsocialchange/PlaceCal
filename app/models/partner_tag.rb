# frozen_string_literal: true

# == Schema Information
#
# Table name: partner_tags
#
#  id         :bigint           not null, primary key
#  partner_id :bigint           not null
#  tag_id     :bigint           not null
#
# Indexes
#
#  index_partner_tags_on_tag_id_and_partner_id  (tag_id,partner_id)
#  index_partner_tags_partner_id_tag_id         (partner_id,tag_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (partner_id => partners.id)
#  fk_rails_...  (tag_id => tags.id)
#
class PartnerTag < ApplicationRecord
  # ==== Associations ====
  belongs_to :partner
  belongs_to :tag

  # ==== Validations ====
  validates :tag_id,
            uniqueness: {
              scope: :partner_id,
              message: 'User cannot be assigned more than once to a tag'
            }
end
