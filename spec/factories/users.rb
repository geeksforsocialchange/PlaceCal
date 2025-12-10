# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@normalcal.org" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { 'citizen' }
    confirmed_at { Time.current }

    # Role-specific factories
    factory :root_user do
      email { 'admin@normalcal.org' }
      first_name { 'Admin' }
      last_name { 'User' }
      role { 'root' }
    end

    factory :citizen_user do
      role { 'citizen' }
    end

    factory :editor_user do
      role { 'editor' }
    end

    factory :neighbourhood_admin do
      role { 'neighbourhood_admin' }

      transient do
        neighbourhood { nil }
      end

      after(:create) do |user, evaluator|
        if evaluator.neighbourhood
          user.neighbourhoods << evaluator.neighbourhood
        end
      end
    end

    factory :partner_admin do
      role { 'partner_admin' }

      transient do
        partner { nil }
      end

      after(:create) do |user, evaluator|
        if evaluator.partner
          user.partners << evaluator.partner
        end
      end
    end

    factory :partnership_admin do
      role { 'partnership_admin' }

      transient do
        partnership_tag { nil }
      end

      after(:create) do |user, evaluator|
        if evaluator.partnership_tag
          user.tags << evaluator.partnership_tag
        end
      end
    end
  end
end
