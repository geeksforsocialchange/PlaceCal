# frozen_string_literal: true

FactoryBot.define do
  factory(:partner) do
    sequence(:name) do |n|
      "Hulme Garden Center #{n}"
    end
    # admin_email nil
    # admin_name nil
    # image nil
    # public_email nil
    # public_phone nil
    # short_description nil
    after(:build) { |partner| partner.turfs = [create(:turf)] }
  end
end
