# frozen_string_literal: true

FactoryBot.define do
  factory(:user) do
    first_name { "Place" }
    last_name { "Cal" }
    password { "password" }
    password_confirmation { "password" }
    sequence :email do |n|
      "test+#{n}@placecal.org"
    end

    factory(:root) { role { "root" } }

    factory(:citizen) { role { "citizen" } }

    factory(:editor) { role { "editor" } }

    factory(:tag_admin) { after(:create) { |user| user.tags = [create(:tag)] } }

    factory(:neighbourhood_admin) do
      after(:create) { |user| user.neighbourhoods = [create(:neighbourhood)] }
    end

    factory(:neighbourhood_region_admin) do
      after(:create) do |user|
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
      after(:create) { |user| user.partners = [create(:partner)] }
    end
  end
end
