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

    # Superuser - accesses everything, use with caution
    factory(:root) do
      role { 'root' }
    end

    factory(:secretary) do
      role { 'secretary' }
    end

    factory(:citizen) do
      role { 'citizen' }
    end

    # Assigning a junk tag/partner to these to check it only works for
    # the specific one assigend in our test
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
