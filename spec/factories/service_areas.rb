# frozen_string_literal: true

# == Schema Information
#
# Table name: service_areas
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  neighbourhood_id :bigint           not null
#  partner_id       :bigint           not null
#
# Indexes
#
#  index_service_areas_on_neighbourhood_id_and_partner_id  (neighbourhood_id,partner_id) UNIQUE
#  index_service_areas_on_partner_id                       (partner_id)
#
# Foreign Keys
#
#  fk_rails_...  (neighbourhood_id => neighbourhoods.id)
#  fk_rails_...  (partner_id => partners.id)
#
FactoryBot.define do
  factory :service_area do
    association :partner
    association :neighbourhood
  end
end
