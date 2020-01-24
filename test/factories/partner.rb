# frozen_string_literal: true

FactoryBot.define do
  factory :partner do
    sequence(:name) do |n|
      "Community Group #{n}"
    end

    public_name { 'Partner Contact Name' }
    public_email { 'contact@communitygroup.org' }
    public_phone { '0161 0000000' }

    partner_email { 'admin@communitygroup.org' }
    partner_name { 'Addy Minny Strator' }
    partner_phone { '0161 0000001' }

    short_description { 'A cool garden centre' }
    url { 'http://example.com' }

    address

    after(:build) { |partner| partner.tags = [create(:tag)] }
    # image nil

    factory :ashton_partner, class: 'Partner' do
      association :address, factory: :ashton_address
    end

    factory :place do
      public_name { 'Place Contact Name' }
    end
  end

end
