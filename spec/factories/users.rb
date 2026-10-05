# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                      :bigint           not null, primary key
#  access_token            :string
#  access_token_expires_at :string
#  avatar                  :string
#  current_sign_in_at      :datetime
#  current_sign_in_ip      :inet
#  email                   :string           default(""), not null
#  encrypted_password      :string           default("")
#  first_name              :string
#  invitation_accepted_at  :datetime
#  invitation_created_at   :datetime
#  invitation_limit        :integer
#  invitation_sent_at      :datetime
#  invitation_token        :string
#  invited_by_type         :string
#  last_name               :string
#  last_sign_in_at         :datetime
#  last_sign_in_ip         :inet
#  phone                   :string
#  remember_created_at     :datetime
#  reset_password_sent_at  :datetime
#  reset_password_token    :string
#  role                    :string           not null
#  sign_in_count           :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  invited_by_id           :integer
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_invitation_token      (invitation_token) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@placecal.org" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { "password123" }
    password_confirmation { "password123" }
    role { "citizen" }

    # Role-specific factories
    factory :root_user, aliases: [:root] do
      email { "admin@placecal.org" }
      first_name { "Admin" }
      last_name { "User" }
      role { "root" }
    end

    factory :citizen_user do
      role { "citizen" }
    end

    factory :editor_user do
      role { "editor" }
    end

    # Neighbourhood admin - citizen role but with neighbourhood association
    factory :neighbourhood_admin do
      role { "citizen" }

      transient do
        neighbourhood { nil }
      end

      after(:create) do |user, evaluator|
        user.neighbourhoods << (evaluator.neighbourhood || create(:riverside_ward))
      end
    end

    # Partner admin - citizen role but with partner association
    factory :partner_admin do
      role { "citizen" }

      transient do
        partner { nil }
      end

      after(:create) do |user, evaluator|
        user.partners << (evaluator.partner || create(:partner))
      end
    end

    # Partnership admin - citizen role but with partnership tag association
    factory :partnership_admin do
      role { "citizen" }

      transient do
        partnership_tag { nil }
      end

      after(:create) do |user, evaluator|
        user.tags << (evaluator.partnership_tag || create(:partnership))
      end
    end
  end
end
