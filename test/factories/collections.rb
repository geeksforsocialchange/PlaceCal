# frozen_string_literal: true

FactoryBot.define do
  factory :collection do
    name { "A Collection Of Events" }
    description { "Information here about the events" }
    route { "named-route" }

    after :create do |collection|
      collection.events = create_list(:event, 5)
    end
  end
end
