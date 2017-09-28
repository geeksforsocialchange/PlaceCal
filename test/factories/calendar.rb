FactoryGirl.define do
  factory(:calendar) do
    address_id nil
    last_import_at "2017-09-27T14:38Z"
    name "HCGC Big Events"
    notices nil
    partner_id 3
    place_id 1
    source "HulmeCommunityGardenCentre"
    strategy "place"
    type "facebook"
  end
end