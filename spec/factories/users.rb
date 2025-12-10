# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@normalcal.org" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { 'citizen' }

    # Role-specific factories
    factory :root_user, aliases: [:root] do
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

    # Neighbourhood admin - citizen role but with neighbourhood association
    factory :neighbourhood_admin do
      role { 'citizen' }

      transient do
        neighbourhood { nil }
      end

      after(:create) do |user, evaluator|
        if evaluator.neighbourhood
          user.neighbourhoods << evaluator.neighbourhood
        else
          # Create a default neighbourhood if none provided
          user.neighbourhoods << create(:riverside_ward)
        end
      end
    end

    # Partner admin - citizen role but with partner association
    factory :partner_admin do
      role { 'citizen' }

      transient do
        partner { nil }
      end

      after(:create) do |user, evaluator|
        if evaluator.partner
          user.partners << evaluator.partner
        else
          # Create a default partner if none provided
          user.partners << create(:partner)
        end
      end
    end

    # Partnership admin - citizen role but with partnership tag association
    factory :partnership_admin do
      role { 'citizen' }

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
