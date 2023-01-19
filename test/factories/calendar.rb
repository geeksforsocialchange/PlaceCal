# frozen_string_literal: true

FactoryBot.define do
  factory(:calendar) do
    name { 'Zion Centre' }

    # VCR.use_cassette(:calendar_events_test
    source { 'https://calendar.google.com/calendar/ical/mgemn0rmm44un8ucifb287coto%40group.calendar.google.com/public/basic.ics' }

    public_contact_name { 'Public Calendar Name' }
    public_contact_email { 'public@communitygroup.com' }
    public_contact_phone { '0161 0000000' }

    partner

    place

    factory :calendar_for_eventbrite, class: 'Calendar' do
      name { 'Eventbrite Calendar 1' }
      # VCR.use_cassette(:eventbrite_events)
      source { 'https://www.eventbrite.co.uk/o/ftm-london-32888898939' }
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
