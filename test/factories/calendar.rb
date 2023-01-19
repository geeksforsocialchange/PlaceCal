# frozen_string_literal: true

FactoryBot.define do
  factory(:calendar) do
    name { 'Zion Centre' }

    # VCR.use_cassette(:import_test_calendar) do
    source { 'https://calendar.google.com/calendar/ical/mgemn0rmm44un8ucifb287coto%40group.calendar.google.com/public/basic.ics' }

    public_contact_name { 'Public Calendar Name' }
    public_contact_email { 'public@communitygroup.com' }
    public_contact_phone { '0161 0000000' }

    partner

    place

    factory :calendar_for_eventbrite, class: 'Calendar' do
      name { 'Eventbrite Calendar 1' }
      # VCR.use_cassette(:eventbrite_events) do
      source { 'https://www.eventbrite.co.uk/o/ftm-london-32888898939' }
    end

    factory :calendar_for_outlook, class: 'Calendar' do
      name { 'Eventbrite Calendar 1' }
      # VCR.use_cassette(:outlook_events) do
      source { 'https://outlook.office365.com/owa/calendar/8a1f38963ce347bab8cfe0d0d8c5ff16@thebiglifegroup.com/5c9fc0f3292e4f0a9af20e18aa6f17739803245039959967240/calendar.ics' }
    end
  end
end

__END__

# frozen_string_literal: true

FactoryBot.define do
  factory(:calendar) do
    sequence :name do |n|
      "Zion Centre #{n}"
    end
    
    # sequence :source do |n|
    #   "https://outlook.office365.com/owa/calendar/#{n}/calendar.ics"
    # end

    # source { 'https://outlook.office365.com/owa/calendar/1/calendar.ics' }
    source { 'https://calendar.google.com/calendar/ical/mgemn0rmm44un8ucifb287coto%40group.calendar.google.com/public/basic.ics'  }
    
    public_contact_name { 'Public Calendar Name' }
    public_contact_email { 'public@communitygroup.com' }
    public_contact_phone { '0161 0000000' }

    partner

    place

    factory :calendar_for_eventbrite, class: 'Calendar' do
      source { 'https://calendar.google.com/calendar/ical/mgemn0rmm44un8ucifb287coto%40group.calendar.google.com/public/basic.ics'  }
    end
  end
end
