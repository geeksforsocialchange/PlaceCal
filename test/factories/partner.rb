# frozen_string_literal: true

FactoryBot.define do
  factory(:partner) do
    sequence(:name) do |n|
      "Hulme Garden Center #{n}"
    end
    # admin_email nil
    # admin_name nil
    # image nil
    public_email 'partner@placecal.org'
    public_phone '0161 0000000'
    short_description 'A cool garden centre'
    address
    url 'http://example.com'
    after(:build) { |partner| partner.turfs = [create(:turf)] }
  end
end
