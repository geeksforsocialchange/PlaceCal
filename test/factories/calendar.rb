# frozen_string_literal: true

FactoryBot.define do
  factory(:calendar) do
    sequence :name do |n|
      "Zion Centre #{n}"
    end
    sequence :source do |n|
	     "https://outlook.office365.com/owa/calendar/#{n}/calendar.ics"
	  end

    public_contact_name { 'Public Calendar Name' }
    public_contact_email { 'public@communitygroup.com'}
    public_contact_phone { '0161 0000000' }

    partnership_contact_name { 'Back Office Manager' }
    partnership_contact_email { 'backoffice@communitygroup.com'}
    partnership_contact_phone { '0161 0000001' }

    partner
  end
end
