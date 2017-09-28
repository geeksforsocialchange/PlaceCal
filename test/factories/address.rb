FactoryGirl.define do
  factory(:address) do
    city "Manchester"
    country_code "UK"
    latitude 53.4651064
    longitude -2.2484797
    postcode "ToFactory: RubyParser exception parsing this attribute after factory generation"
    street_address "ToFactory: RubyParser exception parsing this attribute after factory generation"
    street_address2 nil
    street_address3 nil
  end
end