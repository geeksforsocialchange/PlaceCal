# frozen_string_literal: true

FactoryBot.define do
  factory(:event) do
    summary 'N.A (Narcotics Anonymous)'
    location 'Unformatted Address, Ungeolocated Lane, Manchester'
    dtstart '2017-10-02T12:30Z'
    dtend '2017-10-02T14:00Z'
    is_active true
    address
  end
end
