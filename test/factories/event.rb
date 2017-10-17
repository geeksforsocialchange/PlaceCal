FactoryGirl.define do
  factory(:event) do
    summary 'N.A (Narcotics Anonymous)'
    location 'Unformatted Address, Ungeolocated Lane, Manchester'
    deleted_at nil
    dtend '2017-10-02T14:00Z'
    dtstart '2017-10-02T12:30Z'
    is_active true
    notices nil
    rrule nil
    uid 1
    address
  end
end