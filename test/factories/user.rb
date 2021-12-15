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

    factory(:neighbourhood_region_admin) do
      after(:build) do |user|
        # Create the wards + region
        wards = create_list(:neighbourhood, 5)
        region = create(:neighbourhood_region)

        # Reparent the wards so they are owned by the region
        wards.each do |w|
          county = w.parent.parent
          county.parent = region
          county.save
        end

        # Give ownership to the user
        user.neighbourhoods = [region]
        user.save
      end
    end

    factory(:partner_admin) do
      after(:build) { |user| user.partners = [create(:partner)] }
    end
  end
end
