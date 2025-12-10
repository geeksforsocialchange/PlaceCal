# frozen_string_literal: true

FactoryBot.define do
  factory :collection do
    name { 'An Eventless Collection' }
    description { 'A collection with no events defined' }
    route { 'named-route' }

    factory :collection_with_events, class: 'Collection' do
      name { 'A Collection Of Events' }
      after :create do |collection|
        collection.events = create_list(:event, 5)
      end
    end
  end
end
