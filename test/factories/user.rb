# frozen_string_literal: true

FactoryBot.define do
  factory(:user) do
    first_name { 'Place' }
    last_name { 'Cal' }
    password { 'password' }
    password_confirmation { 'password' }
    sequence :email do |n|
      "test+#{n}@placecal.org"
    end

    factory(:root) do
      role { 'root' }
    end

    factory(:citizen) do
      role { 'citizen' }
    end

    factory(:tag_admin) do
      after(:build) { |user| user.tags = [create(:tag)] }
    end

    factory(:neighbourhood_admin) do
      after(:build) { |user| user.neighbourhoods = [create(:neighbourhood)] }
    end

    factory(:partner_admin) do
      after(:build) { |user| user.partners = [create(:partner)] }
    end
  end
end
