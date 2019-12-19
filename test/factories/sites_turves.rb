# frozen_string_literal: true

FactoryBot.define do
  factory :sites_neighbourhood do
    tag_id { 1 }
    site_id { 1 }
    relation_type { 'MyString' }
  end
end
