# frozen_string_literal: true

FactoryBot.define do
  factory(:calendar) do
    name 'Zion Centre'
    source ''
    strategy 'place'
    type 'outlook'
  end
end
