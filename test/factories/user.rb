FactoryBot.define do
  factory(:citizen) do
    first_name 'Place'
    last_name 'Cal'
    password 'password'
    password_confirmation 'password'
    sequence :email do |n|
      "test+#{n}@placecal.org"
    end

    # Superuser - accesses everything, use with caution
    factory(:root) do
      role 'root'
    end

    # Assigning a junk turf/partner to these to check it only works for
    # the specific one assigend in our test
    factory(:turf_admin) do
      after(:build) { |user| user.turfs << [create(:turf)] }
    end

    factory(:partner_admin) do
      after(:build) { |user| user.turfs << [create(:partner)] }
    end
  end
end
