# frozen_string_literal: true

FactoryBot.define do
  factory :sites_neighbourhood do
    relation_type { 'Primary' }

    neighbourhood

    site
  end
end
