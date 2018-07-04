# frozen_string_literal: true

FactoryBot.define do
  factory(:calendar) do
    sequence :name do |n|
      "Zion Centre #{n}"
    end
    source ''
    strategy 'place'
    type 'outlook'
  end
end
