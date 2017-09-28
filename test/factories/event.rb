FactoryGirl.define do
  factory(:event) do
    address_id nil
    calendar_id 3
    deleted_at nil
    description ""
    dtend "2017-10-02T14:00Z"
    dtstart "2017-10-02T12:30Z"
    is_active true
    location "ToFactory: RubyParser exception parsing this attribute after factory generation"
    notices nil
    partner_id 4
    place_id 3
    rrule [({"table" => {"count" => nil, "ToFactory: RubyParser exception parsing this attribute after factory generation" => "ToFactory: RubyParser exception parsing this attribute after factory generation", "by_day" => ["MO"], "by_hour" => nil, "by_month" => nil, "interval" => 1, "by_minute" => nil, "by_second" => nil, "frequency" => "WEEKLY", "week_start" => "MO", "by_year_day" => nil, "by_month_day" => nil, "by_week_number" => nil, "by_set_position" => nil}})]
    summary "N.A (Narcotics Anonymous)"
    uid "ToFactory: RubyParser exception parsing this attribute after factory generation"
  end
end